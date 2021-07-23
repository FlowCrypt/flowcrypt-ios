//
//  GlobalRouter.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import UIKit

protocol GlobalRouterType {
    func proceed()
    func signIn(with route: GlobalRoutingType)
    func switchActive(user: User)
    func signOut()
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
extension GlobalRouter {
    /// proceed to flow (signing/setup/app) depends on user status (isLoggedIn/isSetupFinished)
    func proceed() {
        userAccountService.cleanupSessions()
        proceed(with: nil)
    }

    private func proceed(with session: SessionType?) {
        logger.logInfo("proceed for session \(session.debugDescription)")
        // make sure it runs on main thread
        let window = keyWindow
        DispatchQueue.main.async {
            AppStartup().initializeApp(window: window, session: session)
        }
    }
}

// MARK: -
extension GlobalRouter {
    func signIn(with route: GlobalRoutingType) {
        logger.logInfo("Sign in with \(route)")

        switch route {
        case .gmailLogin(let viewController):
            googleService.signIn(in: viewController)
                .then(on: .main) { [weak self] session in
                    self?.userAccountService.startSessionFor(user: session)
                    self?.proceed(with: session)
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

    func switchActive(user: User) {
        logger.logInfo("Switching active user \(user)")
        guard let session = userAccountService.switchActiveSessionFor(user: user) else {
            logger.logWarning("Can't switch active user with \(user.email)")
            return
        }
        proceed(with: session)
    }
}
