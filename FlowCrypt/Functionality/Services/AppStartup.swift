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

    init(appContext: AppContext) {
        self.appContext = appContext
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
                try await getUserOrgRulesIfNeeded()
                try chooseView(for: window)
            } catch {
                showErrorAlert(of: error, on: window)
            }
        }
    }

    private func setupCore() async {
        logger.logInfo("Setup Core")
        await Core.shared.startIfNotAlreadyRunning()
    }

    private func setupSession() async throws {
        logger.logInfo("Setup Session")
        try await renewSessionIfValid()
    }

    /// todo - refactor so that it doesn't need getOptionalMailProvider
    private func renewSessionIfValid() async throws {
        guard let mailProvider = await appContext.getOptionalMailProvider() else {
            return
        }
        return try await mailProvider.sessionProvider.renewSession()
    }

    @MainActor
    private func chooseView(for window: UIWindow) throws {
        switch try entryPointForUser() {
        case .mainFlow:
            startWithUserContext(appContext: appContext, window: window) { context in
                let controller = InboxViewContainerController(appContext: context)
                window.rootViewController = SideMenuNavigationController(
                    appContext: context,
                    contentViewController: controller
                )
            }
        case .signIn:
            window.rootViewController = MainNavigationController(
                rootViewController: SignInViewController(appContext: appContext)
            )
        case .setupFlow:
            startWithUserContext(appContext: appContext, window: window) { context in
                do {
                    let controller = try SetupInitialViewController(appContext: context)
                    window.rootViewController = MainNavigationController(rootViewController: controller)
                } catch {
                    window.rootViewController?.showAlert(message: error.localizedDescription)
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

    private func getUserOrgRulesIfNeeded() async throws {
        guard let currentUser = try appContext.encryptedStorage.activeUser else {
            return
        }
        _ = try await appContext.clientConfigurationService.fetch(for: currentUser)
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
    private func showErrorAlert(of error: Error, on window: UIWindow) {
        let alert = UIAlertController(
            title: "error_startup".localized,
            message: "\(error.localizedDescription)",
            preferredStyle: .alert
        )
        let retry = UIAlertAction(
            title: "retry_title".localized,
            style: .default
        ) { _ in
            self.initializeApp(window: window)
        }
        alert.addAction(retry)
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }

    @MainActor
    private func startWithUserContext(appContext: AppContext, window: UIWindow, callback: (AppContextWithUser) -> Void) {
        let session = appContext.session

        guard
            let user = try? appContext.encryptedStorage.activeUser,
            let authType = user.authType
        else {
            let message = "Wrong application state. User not found for session \(session?.description ?? "nil")"
            logger.logError(message)

            if window.rootViewController == nil {
                window.rootViewController = UIViewController()
            }

            window.rootViewController?.showAlert(
                title: "error".localized,
                message: message,
                onOk: { fatalError() }
            )

            return
        }

        callback(appContext.withSession(session: session, authType: authType, user: user))
    }
}
