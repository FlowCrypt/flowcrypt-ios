//
//  GlobalRouter.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol GlobalRouterType {
    func proceed()
    func wipeOutAndReset()
}

struct GlobalRouter: GlobalRouterType {
    private let dataService: DataServiceType = DataService.shared

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

    func wipeOutAndReset() {
        switch dataService.currentAuthType {
        case .oAuthGmail:
            logOutGmailSession()
        case .password:
            logOutUserSession()
        default:
            assertionFailure("User is not logged in")
        }
    }

    private func logOutGmailSession() {
        UserService.shared
            .signOut()
            .then(on: .main) {
                self.proceed()
            }
            .catch(on: .main) { error in
                self.keyWindow
                .rootViewController?
                .showAlert(error: error, message: "Could not log out")
            }
    }

    private func logOutUserSession() {
        Imap.shared.disconnect()
        dataService.logOutAndDestroyStorage()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.proceed()
        }
    }
}
