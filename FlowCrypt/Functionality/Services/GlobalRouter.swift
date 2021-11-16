//
//  GlobalRouter.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

protocol GlobalRouterType {
    @MainActor func proceed()
    @MainActor func signIn(with route: GlobalRoutingType)
    @MainActor func switchActive(user: User)
    @MainActor func signOut()
}

enum GlobalRoutingType {
    // Login using Gmail web view
    case gmailLogin(UIViewController)
    // Login with Google authenticated use
    case other(SessionType)
}

enum GlobalRoutingError: Error {
    case missedRootViewController
}

// MARK: - GlobalRouter
final class GlobalRouter: GlobalRouterType {

    @MainActor private var keyWindow: UIWindow {
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
extension GlobalRouter {
    /// proceed to flow (signing/setup/app) depends on user status (isLoggedIn/isSetupFinished)
    @MainActor func proceed() {
        validateEncryptedStorage {
            userAccountService.cleanupSessions()
            proceed(with: nil)
        }
    }

    @MainActor private func validateEncryptedStorage(_ completion: () -> Void) {
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

    @MainActor private func proceed(with session: SessionType?) {
        logger.logInfo("proceed for session \(session.debugDescription)")
        // make sure it runs on main thread
        let window = keyWindow
        DispatchQueue.main.async {
            AppStartup().initializeApp(window: window, session: session)
        }
    }

    @MainActor private func handleGmailError(_ error: Error) {
        logger.logInfo("gmail login failed with error \(error.localizedDescription)")
        if let gmailUserError = error as? GoogleUserServiceError,
           case .userNotAllowedAllNeededScopes(let missingScopes) = gmailUserError {
            DispatchQueue.main.async {
                let topNavigation = (self.keyWindow.rootViewController as? UINavigationController)
                let checkAuthViewControlelr = CheckAuthScopesViewController(missingScopes: missingScopes)
                topNavigation?.pushViewController(checkAuthViewControlelr, animated: true)
            }
        }
    }
}

// MARK: -
extension GlobalRouter {
    @MainActor func signIn(with route: GlobalRoutingType) {
        logger.logInfo("Sign in with \(route)")

        switch route {
        case .gmailLogin(let viewController):
            Task {
                do {
                    let session = try await googleService.signIn(in: viewController)
                    DispatchQueue.main.async {
                        self.userAccountService.startSessionFor(user: session)
                        self.proceed(with: session)
                    }
                } catch {
                    self.handleGmailError(error)
                }
            }
        case .other(let session):
            userAccountService.startSessionFor(user: session)
            proceed(with: session)
        }
    }

    @MainActor func signOut() {
        if let session = userAccountService.startActiveSessionForNextUser() {
            logger.logInfo("Start session for another email user \(session)")
            proceed(with: session)
        } else {
            logger.logInfo("Sign out")
            userAccountService.cleanup()
            proceed()
        }
    }

    @MainActor func switchActive(user: User) {
        logger.logInfo("Switching active user \(user)")
        guard let session = userAccountService.switchActiveSessionFor(user: user) else {
            logger.logWarning("Can't switch active user with \(user.email)")
            return
        }
        proceed(with: session)
    }
}
