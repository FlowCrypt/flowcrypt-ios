//
//  GlobalRouter.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

protocol GlobalRouterType {
    func proceed()
    func signIn(with rout: GlobalRoutingType)
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
        proceed(with: nil)
    }

    private func proceed(with session: SessionType?) {
        // make sure it runs on main thread
        let window = keyWindow
        DispatchQueue.main.async {
            AppStartup().initializeApp(window: window, session: session)
        }
    }
}

// MARK: -
extension GlobalRouter {
    func signIn(with rout: GlobalRoutingType) {
        switch rout {
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
        guard let session = userAccountService.startActiveSessionForNextUser() else {
            // TODO: - ANTON
            // keyWindow.rootViewController?.showAlert(error: error, message: "Could not sign out")
            debugPrint("[GlobalRouter] signOut error")
            return
        }
        proceed(with: session)
    }

    func switchActive(user: User) {
        guard let session = userAccountService.switchActiveSessionFor(user: user) else {
            debugPrint("[GlobalRouter] can't switch active user with \(user.email)")
            return
        }
        proceed(with: session)
    }
}
