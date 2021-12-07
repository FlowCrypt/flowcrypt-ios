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
    func signIn(appContext: AppContext, route: GlobalRoutingType) async
    func askForContactsPermission(for route: GlobalRoutingType, appContext: AppContext) async throws
    func switchActive(user: User, appContext: AppContext)
    func signOut(appContext: AppContext)
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
            let appContext = try AppContext.setUpAppContext(globalRouter: self)
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

    func signIn(appContext: AppContext, route: GlobalRoutingType) async {
        logger.logInfo("Sign in with \(route)")
        do {
            switch route {
            case .gmailLogin(let viewController):
                let googleService = GoogleUserService(
                    currentUserEmail: appContext.dataService.currentUser?.email,
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
                let session = try await googleService.signIn(
                    in: viewController,
                    scopes: GeneralConstants.Gmail.mailScope
                )
                try appContext.userAccountService.startSessionFor(session: session)
                proceed(with: appContext.withSession(session))
            case .other(let session):
                try appContext.userAccountService.startSessionFor(session: session)
                proceed(with: appContext.withSession(session))
            }
        } catch {
            logger.logError("Failed to sign in due to \(error.localizedDescription)")
            handleSignInError(error: error, appContext: appContext)
        }
    }

    func signOut(appContext: AppContext) {
        do {
            if let session = try appContext.userAccountService.startActiveSessionForNextUser() {
                logger.logInfo("Start session for another email user \(session)")
                proceed(with: appContext.withSession(session))
            } else {
                logger.logInfo("Sign out")
                appContext.userAccountService.cleanup()
                proceed()
            }
        } catch {
            logger.logError("Failed to sign out due to \(error.localizedDescription)")
            hanleFatalError(error)
        }
    }

    func askForContactsPermission(for route: GlobalRoutingType, appContext: AppContext) async throws {
        logger.logInfo("Ask for contacts permission with \(route)")

        switch route {
        case .gmailLogin(let viewController):
            do {
                let googleService = GoogleUserService(
                    currentUserEmail: appContext.dataService.currentUser?.email,
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
                let session = try await googleService.signIn(
                    in: viewController,
                    scopes: GeneralConstants.Gmail.contactsScope
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

    func switchActive(user: User, appContext: AppContext) {
        logger.logInfo("Switching active user \(user)")
        do {
            guard let session = try appContext.userAccountService.switchActiveSessionFor(user: user) else {
                logger.logWarning("Can't switch active user with \(user.email)")
                return
            }
            proceed(with: appContext.withSession(session))
        } catch {
            logger.logError("Failed to switch active user due to \(error.localizedDescription)")
            hanleFatalError(error)
        }
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

    @MainActor
    private func proceed(with appContext: AppContext) {
        logger.logInfo("proceed for session: \(appContext.session?.description ?? "nil")")
        AppStartup(appContext: appContext).initializeApp(window: keyWindow)
    }

    @MainActor
    private func handleSignInError(error: Error, appContext: AppContext) {
        if let gmailUserError = error as? GoogleUserServiceError {
            logger.logInfo("Gmail login failed with error: \(gmailUserError.errorMessage)")

            if case .cancelledAuthorization = gmailUserError {
                proceed()
                return
            }

            if case .userNotAllowedAllNeededScopes = gmailUserError {
                let navigationController = keyWindow.rootViewController?.navigationController
                let checkAuthViewController = CheckMailAuthViewController(appContext: appContext)
                navigationController?.pushViewController(checkAuthViewController, animated: true)
                return
            }
        }

        keyWindow.rootViewController?.showAlert(
            title: "error".localized,
            message: error.localizedDescription,
            onOk: { [weak self] in self?.proceed() }
        )
    }

    @MainActor
    private func hanleFatalError(_ error: Error) {
        keyWindow.rootViewController = FatalErrorViewController(error: error)
    }
}
