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
    func signIn(with route: GlobalRoutingType)
    func askForContactsPermission(for route: GlobalRoutingType) async throws
    func switchActive(user: User)
    func signOut()
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

    private let userAccountService: UserAccountServiceType
    private let googleService: GoogleUserService

    private lazy var logger = Logger.nested(in: Self.self, with: .userAppStart)

    init(
        userAccountService: UserAccountServiceType = UserAccountService(),
        googleService: GoogleUserService = GoogleUserService()
    ) {
        self.userAccountService = userAccountService
        self.googleService = googleService
    }
}

// MARK: - Proceed
extension GlobalRouter: GlobalRouterType {
    /// proceed to flow (signing/setup/app) depends on user status (isLoggedIn/isSetupFinished)
    func proceed() {
        validateEncryptedStorage {
            userAccountService.cleanupSessions()
            proceed(with: nil)
        }
    }

    func signIn(with route: GlobalRoutingType) {
        logger.logInfo("Sign in with \(route)")

        switch route {
        case .gmailLogin(let viewController):
            Task {
                do {
                    let session = try await googleService.signIn(
                        in: viewController,
                        scopes: GeneralConstants.Gmail.mailScope
                    )
                    self.userAccountService.startSessionFor(user: session)
                    self.proceed(with: session)
                } catch {
                    self.handleGmailError(error, in: viewController)
                }
            }
        case .other(let session):
            userAccountService.startSessionFor(user: session)
            proceed(with: session)
        }
    }

    func signOut() {
        if let session = userAccountService.startActiveSessionForNextUser() {
            logger.logInfo("Start session for another email user \(session)")
            proceed(with: session)
        } else {
            logger.logInfo("Sign out")
            userAccountService.cleanup()
            proceed()
        }
    }

    func askForContactsPermission(for route: GlobalRoutingType) async throws {
        logger.logInfo("Ask for contacts permission with \(route)")

        switch route {
        case .gmailLogin(let viewController):
            do {
                let session = try await googleService.signIn(
                    in: viewController,
                    scopes: GeneralConstants.Gmail.contactsScope
                )
                self.userAccountService.startSessionFor(user: session)
            } catch {
                logger.logInfo("Contacts scope failed with error \(error.errorMessage)")
                throw error
            }
        case .other:
            break
        }
    }

    func switchActive(user: User) {
        logger.logInfo("Switching active user \(user)")
        guard let session = userAccountService.switchActiveSessionFor(user: user) else {
            logger.logWarning("Can't switch active user with \(user.email)")
            return
        }
        proceed(with: session)
    }

    @MainActor
    private func validateEncryptedStorage(_ completion: () -> Void) {
        let storage = EncryptedStorage()
        do {
            try storage.validate()
            completion()
        } catch {
            let controller = InvalidStorageViewController(
                error: error,
                encryptedStorage: storage,
                router: self
            )
            keyWindow.rootViewController = UINavigationController(rootViewController: controller)
            keyWindow.makeKeyAndVisible()
        }
    }

    @MainActor
    private func proceed(with session: SessionType?) {
        logger.logInfo("proceed for session \(session.debugDescription)")
        AppStartup().initializeApp(window: keyWindow, session: session)
    }

    @MainActor
    private func handleGmailError(_ error: Error, in viewController: UIViewController) {
        logger.logInfo("gmail login failed with error \(error.errorMessage)")
        if let gmailUserError = error as? GoogleUserServiceError,
           case .userNotAllowedAllNeededScopes = gmailUserError {
            let navigationController = viewController.navigationController
            let checkAuthViewController = CheckMailAuthViewController()
            navigationController?.pushViewController(checkAuthViewController, animated: true)
        }
    }
}
