//
//  StartupChecks.swift
//  FlowCrypt
//
//  Created by luke on 13/2/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

private let logger = Logger.nested("AppStart")

struct AppStartup {
    private enum EntryPoint {
        case signIn, setupFlow(UserId), mainFlow
    }

    private let appContext: AppContext
    private let core: Core

    init(appContext: AppContext, core: Core = .shared) {
        self.appContext = appContext
        self.core = core
    }

    @MainActor
    func initializeApp(window: UIWindow) {
        logger.logInfo("Initialize application with session \(appContext.session.debugDescription)")

        Task {
            window.rootViewController = BootstrapViewController()
            window.makeKeyAndVisible()

            do {
                await setupCore()
                try await setupSession()
                try await chooseView(for: window)
            } catch {
                showErrorAlert(message: error.errorMessage, on: window)
            }
        }
    }

    // Update `isRevoked` value (PubKeyRealmObject `isRevoked` was added in realm schema version 10[2022 May 23th])
    // Need to set correct `isRevoked` value when user first opens app from older versions
    @MainActor
    private func checkAndUpdateIsRevoked(context: AppContextWithUser) async throws {
        let revokedUpdatedFlag = "IS_PUB_KEY_REVOKED_UPDATED"
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: revokedUpdatedFlag) {
            return
        }
        // Added storage access directly because this function logic should be removed in the near future
        let storage = try context.encryptedStorage.storage
        let pubKeyObjects = storage.objects(PubKeyRealmObject.self).unique()

        for pubKeyObject in pubKeyObjects {
            let parsedKey = try await core.parseKeys(armoredOrBinary: pubKeyObject.armored.data())
            try storage.write {
                if let keyDetail = parsedKey.keyDetails.first {
                    pubKeyObject.isRevoked = keyDetail.revoked
                }
            }
        }

        userDefaults.set(true, forKey: revokedUpdatedFlag)
    }

    // Update `isRevoked` value (KeypairRealmObject `isRevoked` was added in realm schema version 11[2022 May 25th])
    // Need to set correct `isRevoked` value when user first opens app from older versions
    @MainActor
    private func checkAndUpdateKeyPairIsRevoked(context: AppContextWithUser) async throws {
        let revokedUpdatedFlag = "IS_KEY_PAIR_REVOKED_UPDATED"
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: revokedUpdatedFlag) {
            return
        }
        // Added storage access directly because this function logic should be removed in the near future
        let storage = try context.encryptedStorage.storage
        let keyPairObjects = storage.objects(KeypairRealmObject.self).unique()

        for keyPairObject in keyPairObjects {
            let parsedKey = try await core.parseKeys(armoredOrBinary: keyPairObject.private.data())
            try storage.write {
                if let keyDetail = parsedKey.keyDetails.first {
                    keyPairObject.isRevoked = keyDetail.revoked
                }
            }
        }

        userDefaults.set(true, forKey: revokedUpdatedFlag)
    }

    // Update `lastModified` value (KeyPairRealm `lastModified` was added in realm schema version 9)
    // Need to set correct `lastModified` value when user first opens app from older versions
    @MainActor
    private func checkAndUpdateLastModified(context: AppContextWithUser) async throws {
        let lastModifiedUpdatedFlag = "IS_LAST_MODIFIED_FLAG_UPDATED"
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: lastModifiedUpdatedFlag) {
            return
        }
        // Added storage access directly because this function logic should be removed in the near future
        let storage = try context.encryptedStorage.storage
        let keyPairs = storage.objects(KeypairRealmObject.self).where {
            $0.user.email.equals(context.user.email)
        }.unique()

        for keyPair in keyPairs {
            let parsedKey = try await core.parseKeys(armoredOrBinary: keyPair.public.data())
            try storage.write {
                if let keyDetail = parsedKey.keyDetails.first, let lastModified = keyDetail.lastModified {
                    keyPair.lastModified = lastModified
                } else {
                    storage.delete(keyPair)
                }
            }
        }

        userDefaults.set(true, forKey: lastModifiedUpdatedFlag)
    }

    private func setupCore() async {
        logger.logInfo("Setup Core")
        await core.startIfNotAlreadyRunning()
    }

    private func setupSession() async throws {
        logger.logInfo("Setup Session")
        try await renewSessionIfValid()
    }

    /// todo - refactor so that it doesn't need getOptionalMailProvider
    private func renewSessionIfValid() async throws {
        guard let mailProvider = try await appContext.getOptionalMailProvider() else {
            return
        }
        try await mailProvider.sessionProvider.renewSession()
    }

    @MainActor
    private func chooseView(for window: UIWindow) async throws {
        switch try entryPointForUser() {
        case .mainFlow:
            try await startWithUserContext(appContext: appContext, window: window) { context in
                Task {
                    // TODO: need to remove this after a few versions.
                    // https://github.com/FlowCrypt/flowcrypt-ios/pull/1510#discussion_r861051611
                    try await checkAndUpdateLastModified(context: context)
                    // This one too.(which was added in schema 10)
                    try await checkAndUpdateIsRevoked(context: context)
                    // This was added in schema 11
                    try await checkAndUpdateKeyPairIsRevoked(context: context)
                    let controller = try InboxViewContainerController(appContext: context)
                    window.rootViewController = try SideMenuNavigationController(
                        appContext: context,
                        contentViewController: controller
                    )
                }
            }
        case .signIn:
            window.rootViewController = MainNavigationController(
                rootViewController: SignInViewController(appContext: appContext)
            )
        case .setupFlow:
            try await startWithUserContext(appContext: appContext, window: window) { context in
                Task {
                    do {
                        let controller = try await SetupInitialViewController(appContext: context)
                        window.rootViewController = MainNavigationController(rootViewController: controller)
                    } catch {
                        window.rootViewController?.showAlert(
                            title: "error_login".localized,
                            message: error.errorMessage
                        )
                    }
                }
            }
        }
    }

    private func entryPointForUser() throws -> EntryPoint {
        guard let activeUser = try appContext.encryptedStorage.activeUser else {
            logger.logInfo("User is not logged in -> signIn")
            return .signIn
        }

        if try appContext.encryptedStorage.doesAnyKeypairExist(for: activeUser.email) {
            logger.logInfo("Setup finished -> mainFlow")
            return .mainFlow
        } else if let session = appContext.session, let userId = try makeUserIdForSetup(session: session) {
            logger.logInfo("User with session \(session) -> setupFlow")
            return .setupFlow(userId)
        } else {
            logger.logInfo("User is not signed in -> mainFlow")
            return .signIn
        }
    }

    private func makeUserIdForSetup(session: SessionType) throws -> UserId? {
        guard let activeUser = try appContext.encryptedStorage.activeUser else {
            Logger.logInfo("Can't create user id for setup")
            return nil
        }

        var userId = UserId(email: activeUser.email, name: activeUser.name)

        switch session {
        case let .google(email, name, _):
            guard activeUser.email != email else {
                logger.logInfo("UserId = current user id")
                return userId
            }
            logger.logInfo("UserId = google user id")
            userId = UserId(email: email, name: name)
        case let .session(userObject):
            guard userObject.email != activeUser.email else {
                Logger.logInfo("UserId = current user id")
                return userId
            }
            Logger.logInfo("UserId = session user id")
            userId = UserId(email: userObject.email, name: userObject.name)
        }

        return userId
    }

    @MainActor
    private func showErrorAlert(message: String, on window: UIWindow) {
        if window.rootViewController == nil {
            window.rootViewController = UIViewController()
        }
        let alert = UIAlertController(
            title: "error_startup".localized,
            message: message,
            preferredStyle: .alert
        )
        let retry = UIAlertAction(
            title: "retry_title".localized,
            style: .default
        ) { _ in
            self.initializeApp(window: window)
        }
        let logout = UIAlertAction(
            title: "log_out".localized,
            style: .default
        ) { _ in
            Task {
                do {
                    try await appContext.globalRouter.signOut(appContext: appContext)
                } catch {
                    Logger.logError("Logout failed due to \(error.errorMessage)")
                }
            }
        }
        alert.addAction(retry)
        alert.addAction(logout)
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }

    @MainActor
    private func startWithUserContext(appContext: AppContext, window: UIWindow, callback: (AppContextWithUser) -> Void) async throws {
        let session = appContext.session

        guard
            let user = try appContext.encryptedStorage.activeUser,
            let authType = user.authType
        else {
            let sessionName = appContext.session?.description ?? "nil"
            let message = "error_wrong_app_state".localizeWithArguments(sessionName)

            logger.logError(message)

            showErrorAlert(message: message, on: window)
            return
        }

        let contextWithUser = try await appContext.with(session: session, authType: authType, user: user)
        callback(contextWithUser)
    }
}
