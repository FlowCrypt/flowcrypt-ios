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
    func signIn(with type: SignInType)
    func signOut()
}

enum SignInType {
    case gmail, outlook, other(UserObject)
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
        // make sure it runs on main thread
        let window = keyWindow
        DispatchQueue.main.async {
            AppStartup.shared.initializeApp(window: window)
        }
    }
}

// MARK: - SignIn
extension GlobalRouter {
    func signIn(with type: SignInType) {
        guard let viewController = self.keyWindow.rootViewController else {
            assertionFailure("Failed to sign in")
            return
        }

        startUserSessionFor(signIn: type, in: viewController)
            .then(on: .main) { [weak self] in
                self?.proceed()
            }
            .catch(on: .main) { error in
                viewController.showAlert(error: error, message: "Failed to sign in")
            }
    }

    private func startUserSessionFor(signIn type: SignInType, in viewController: UIViewController) -> Promise<Void> {
        Promise<Void> { [weak self] (resolve, reject) in
            guard let self = self else {
                return reject(AppErr.nilSelf)
            }

            switch type {
            case .gmail:
                let userSession = try await(self.googleService.signIn(in: viewController))
                try await(self.userAccountService.startFor(user: userSession))
                resolve(())
            case .other(let user):
                try await(self.userAccountService.startFor(user: .session(user)))
                resolve(())
            case .outlook:
                resolve(())
            }
        }
    }

    /// Start user session, execute block and proceed to dedicated flow
    @discardableResult
    private func startFor(user type: SessionType, executeBeforeStart: (() -> Void)?) -> Promise<Void> {
        Promise { [weak self] (resolve, _) in
            guard let self = self else { throw AppErr.nilSelf }

            try await(self.userAccountService.startFor(user: type))
            executeBeforeStart?()
            self.proceed()

            resolve(())
        }
    }
}

// MARK: - SignOut
extension GlobalRouter {
    // TODO: - ANTON
    func signOut() {
        userAccountService.logOutCurrentUser()
            .then(on: .main) { [weak self] _ in
                self?.proceed()
            }
            .catch(on: .main) { [weak self] error in
                self?.keyWindow.rootViewController?.showAlert(error: error, message: "Could not sign out")
            }
    }
}
