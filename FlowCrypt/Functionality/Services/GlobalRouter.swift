//
//  GlobalRouter.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

@MainActor
protocol GlobalRouterType {
    func proceed()
    func signIn(appContext: AppContext, route: GlobalRoutingType, email: String?) async
    func renderMissingPermissionsView(appContext: AppContext)
    func askForContactsPermission(for route: GlobalRoutingType, appContext: AppContextWithUser) async throws
    func switchActive(user: User, appContext: AppContext) async throws
    func signOut(appContext: AppContext) async throws
}

enum GlobalRoutingType {
    // Login using Gmail web view
    case gmailLogin(UIViewController)
    // Login with Google authenticated use
    case other(SessionType)
}

// MARK: - GlobalRouter
final class GlobalRouter {

    private var keyWindow: UIWindow {
        let application = UIApplication.shared
        guard let delegate = (application.delegate as? AppDelegate) else {
            fatalError("missing AppDelegate in GlobalRouter.reset()")
        }
        return delegate.window
    }

    private lazy var logger = Logger.nested(in: Self.self, with: .userAppStart)
}

// MARK: - Proceed
extension GlobalRouter: GlobalRouterType {

    /// proceed to flow (signing/setup/app) depends on user status (isLoggedIn/isSetupFinished)
    func proceed() {
        do {
            let appContext = try AppContext.setup(globalRouter: self)
            do {
                try appContext.encryptedStorage.validate()
                proceed(with: appContext)
            } catch {
                renderInvalidStorageView(error: error, encryptedStorage: nil)
            }
        } catch {
            renderInvalidStorageView(error: error, encryptedStorage: nil)
        }
    }

    func signIn(appContext: AppContext, route: GlobalRoutingType, email: String?) async {
        logger.logInfo("Sign in with \(route)")
        do {
            switch route {
            case .gmailLogin(let viewController):
                viewController.showSpinner()

                let email = try email ?? appContext.encryptedStorage.activeUser?.email
                let googleService = GoogleUserService(
                    currentUserEmail: email,
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
                let session = try await googleService.signIn(
                    in: viewController,
                    scopes: GeneralConstants.Gmail.mailScope,
                    userEmail: email
                )
                try appContext.userAccountService.startSessionFor(session: session)
                viewController.hideSpinner()
                try await proceed(with: appContext, session: session)
            case .other(let session):
                try appContext.userAccountService.startSessionFor(session: session)
                try await proceed(with: appContext, session: session)
            }
        } catch {
            if case .gmailLogin(let viewController) = route {
                viewController.hideSpinner()
            }
            logger.logError("Failed to sign in due to \(error.errorMessage)")
            handleSignInError(error: error, appContext: appContext)
        }
    }

    func signOut(appContext: AppContext) async throws {
        if let session = try appContext.userAccountService.startActiveSessionForNextUser() {
            logger.logInfo("Start session for another email user \(session)")
            try await proceed(with: appContext, session: session)
        } else {
            logger.logInfo("Sign out")
            try appContext.userAccountService.cleanup()
            proceed()
        }
    }

    func askForContactsPermission(for route: GlobalRoutingType, appContext: AppContextWithUser) async throws {
        logger.logInfo("Ask for contacts permission with \(route)")

        switch route {
        case .gmailLogin(let viewController):
            do {
                let googleService = GoogleUserService(
                    currentUserEmail: appContext.user.email,
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
                let session = try await googleService.signIn(
                    in: viewController,
                    scopes: GeneralConstants.Gmail.contactsScope,
                    userEmail: appContext.user.email
                )
                try appContext.userAccountService.startSessionFor(session: session)
                // todo? - no need to update context itself with new session?
            } catch {
                logger.logInfo("Contacts scope failed with error \(error.errorMessage)")
                throw error
            }
        case .other:
            break
        }
    }

    func switchActive(user: User, appContext: AppContext) async throws {
        logger.logInfo("Switching active user \(user)")
        guard let session = try appContext.userAccountService.switchActiveSessionFor(user: user) else {
            logger.logWarning("Can't switch active user with \(user.email)")
            return
        }
        try await proceed(with: appContext, session: session)
    }

    @MainActor
    private func renderInvalidStorageView(error: Error, encryptedStorage: EncryptedStorageType?) {
        // EncryptedStorage is nil if we could not successfully initialize it
        let controller = InvalidStorageViewController(
            error: error,
            encryptedStorage: encryptedStorage,
            router: self
        )
        keyWindow.rootViewController = UINavigationController(rootViewController: controller)
        keyWindow.makeKeyAndVisible()
    }

    func renderMissingPermissionsView(appContext: AppContext) {
        let controller = CheckMailAuthViewController(
            appContext: appContext,
            decorator: CheckMailAuthViewDecorator(type: .invalidGrant)
        )
        keyWindow.rootViewController = MainNavigationController(rootViewController: controller)
        keyWindow.makeKeyAndVisible()
    }

    @MainActor
    private func proceed(with appContext: AppContext) {
        logger.logInfo("proceed for session: \(appContext.session?.description ?? "nil")")
        AppStartup(appContext: appContext).initializeApp(window: keyWindow)
    }

    @MainActor
    private func proceed(with appContext: AppContext, session: SessionType) async throws {
        logger.logInfo("proceed for session: \(session.description)")
        guard
            let user = try appContext.encryptedStorage.activeUser,
            let authType = user.authType
        else {
            let message = "Wrong application state. User not found for session \(session.description)"
            logger.logError(message)

            keyWindow.rootViewController?.showAlert(
                title: "error".localized,
                message: message,
                onOk: { fatalError() }
            )

            return
        }

        let appContextWithUser = try await appContext.with(session: session, authType: authType, user: user)
        AppStartup(appContext: appContextWithUser).initializeApp(window: keyWindow)
    }

    @MainActor
    private func handleSignInError(error: Error, appContext: AppContext) {
        if let gmailUserError = error as? GoogleUserServiceError {
            logger.logInfo("Gmail login failed with error: \(gmailUserError.errorMessage)")

            if case .cancelledAuthorization = gmailUserError {
                return
            }

            if case .userNotAllowedAllNeededScopes = gmailUserError {
                let rootViewController = keyWindow.rootViewController
                let navigationController = rootViewController as? UINavigationController ?? rootViewController?.navigationController
                let checkAuthViewController = CheckMailAuthViewController(
                    appContext: appContext,
                    decorator: CheckMailAuthViewDecorator(type: .setup)
                )
                navigationController?.pushViewController(checkAuthViewController, animated: true)
                return
            }
        }

        keyWindow.rootViewController?.showAlert(
            title: "error_login".localized,
            message: error.errorMessage
        )
    }
}
