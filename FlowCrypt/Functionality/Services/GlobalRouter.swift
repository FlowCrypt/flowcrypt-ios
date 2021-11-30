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
    func signIn(appContext: AppContext, route: GlobalRoutingType)
    func askForContactsPermission(appContext: AppContext, for route: GlobalRoutingType) async throws
    func switchActive(appContext: AppContext, user: User)
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

    func signIn(appContext: AppContext, route: GlobalRoutingType) {
        logger.logInfo("Sign in with \(route)")

        switch route {
        case .gmailLogin(let viewController):
            Task {
                do {
                    let googleService = GoogleUserService(
                        currentUserEmail: appContext.dataService.currentUser?.email,
                        appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                    )
                    let session = try await googleService.signIn(
                        in: viewController,
                        scopes: GeneralConstants.Gmail.mailScope
                    )
                    appContext.userAccountService.startSessionFor(session: session)
                    self.proceed(with: appContext.withSession(session))
                } catch {
                    self.handleGmailError(appContext: appContext, error, in: viewController)
                }
            }
        case .other(let session):
            appContext.userAccountService.startSessionFor(session: session)
            proceed(with: appContext.withSession(session))
        }
    }

    func signOut(appContext: AppContext) {
        if let session = appContext.userAccountService.startActiveSessionForNextUser() {
            logger.logInfo("Start session for another email user \(session)")
            proceed(with: appContext.withSession(session))
        } else {
            logger.logInfo("Sign out")
            appContext.userAccountService.cleanup()
            proceed()
        }
    }

    func askForContactsPermission(appContext: AppContext, for route: GlobalRoutingType) async throws {
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
                appContext.userAccountService.startSessionFor(session: session)
                // todo? - no need to update context itself with new session?
            } catch {
                logger.logInfo("Contacts scope failed with error \(error.errorMessage)")
                throw error
            }
        case .other:
            break
        }
    }

    func switchActive(appContext: AppContext, user: User) {
        logger.logInfo("Switching active user \(user)")
        guard let session = appContext.userAccountService.switchActiveSessionFor(user: user) else {
            logger.logWarning("Can't switch active user with \(user.email)")
            return
        }
        proceed(with: appContext.withSession(session))
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
    private func handleGmailError(appContext: AppContext, _ error: Error, in viewController: UIViewController) {
        logger.logInfo("gmail login failed with error \(error.errorMessage)")
        if let gmailUserError = error as? GoogleUserServiceError,
           case .userNotAllowedAllNeededScopes = gmailUserError {
            let navigationController = viewController.navigationController
            let checkAuthViewController = CheckMailAuthViewController(appContext: appContext)
            navigationController?.pushViewController(checkAuthViewController, animated: true)
        }
    }
}
