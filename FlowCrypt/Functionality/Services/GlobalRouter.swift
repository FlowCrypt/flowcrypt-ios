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

    func logOut() -> Promise<Void>

    func signIn(in viewController: UIViewController, with type: SignInType)
    func signOut(in viewController: UIViewController)
}

final class GlobalRouter: GlobalRouterType {
    private var keyWindow: UIWindow {
        let application = UIApplication.shared
        guard let delegate = (application.delegate as? AppDelegate) else {
            fatalError("missing AppDelegate in GlobalRouter.reset()")
        }
        return delegate.window
    }

    private let userAccountService: UserAccountServiceType

    init(userAccountService: UserAccountServiceType = UserAccountService()) {
        self.userAccountService = userAccountService
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
    func signIn(in viewController: UIViewController, with type: SignInType) {
        switch type {
        case .gmail:




//            userAccountService.signIn(in: viewController)
//                .then(on: .main) { [weak self] _ in
//                    self?.proceedToRecover()
//                }
//                .catch(on: .main) { [weak self] error in
//                    self?.showAlert(error: error, message: "Failed to sign in")
//                }
        break
        case .outlook:
            break
        case .other:
            break
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

// MARK: - SignIn
extension GlobalRouter {
    func logOut() -> Promise<Void> {
        userAccountService.logOutCurrentUser()
    }

    func signOut(in viewController: UIViewController) {
//        userAccountService.signOut()
//            .then(on: .main) { [weak self] _ in
//                self?.router.proceed()
//            }
//            .catch(on: .main) { [weak self] error in
//                viewController.showAlert(error: error, message: "Could not sign out")
//            }
    }
}
