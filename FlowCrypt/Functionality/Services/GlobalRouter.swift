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
    func startFor(user type: SessionType, executeBeforeStart: (() -> Void)?) -> Promise<Void>
    func logOut() -> Promise<Void>
}

struct GlobalRouter: GlobalRouterType {
    private let dataService: DataServiceType
    private let userAccountService: UserAccountServiceType

    init(
        dataService: DataServiceType = DataService.shared,
        userAccountService: UserAccountServiceType = UserAccountService()
    ) {
        self.dataService = dataService
        self.userAccountService = userAccountService
    }

    private var keyWindow: UIWindow {
        let application = UIApplication.shared
        guard let delegate = (application.delegate as? AppDelegate) else {
            fatalError("missing AppDelegate in GlobalRouter.reset()")
        }
        return delegate.window
    }

    /// proceed to flow (signing/setup/app) depends on user status (isLoggedIn/isSetupFinished)
    func proceed() {
        // make sure it runs on main thread
        let window = keyWindow
        DispatchQueue.main.async {
            AppStartup.shared.initializeApp(window: window)
        }
    }

    /// Start user session, execute block and proceed to dedicated flow
    @discardableResult
    func startFor(user type: SessionType, executeBeforeStart: (() -> Void)?) -> Promise<Void> {
        Promise { (resolve, _) in
            try await(self.userAccountService.startFor(user: type))
            executeBeforeStart?()
            self.proceed()
            resolve(())
        }
    }

    func logOut() -> Promise<Void> {
        userAccountService.logOutCurrentUser()
    }
}
