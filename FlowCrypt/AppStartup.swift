//
//  StartupChecks.swift
//  FlowCrypt
//
//  Created by luke on 13/2/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import GoogleSignIn

class AppStartup {

    public func initializeApp(window: UIWindow) {
        let start = DispatchTime.now()
        DispatchQueue.promises = .global()
        window.rootViewController = BootstrapViewController()
        window.makeKeyAndVisible()
        Promise<Void> {
            Core.shared.startInBackgroundIfNotAlreadyRunning()
            try self.setUpAuthentiation()
            try await(DataManager.shared.performMigrationIfNeeded())
            try await(self.renewSessionIfValid())
        }.then(on: .main) {
            self.chooseView(window: window)
            log("AppStartup", error: nil, res: nil, start: start)
        }.catch(on: .main) { err in
            let alert = UIAlertController(title: "Startup Error", message: "\(err)", preferredStyle: .alert)
            window.rootViewController?.present(alert, animated: true, completion: nil)
            log("AppStartup", error: err, res: nil, start: start)
        }
    }

    private func setUpAuthentiation() throws {
        guard let googleSignIn = GIDSignIn.sharedInstance() else { throw AppErr.general("Unexpected nil GIDSignIn") }
        googleSignIn.clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        googleSignIn.scopes = [
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/",
        ]
        googleSignIn.delegate = UserService.shared
    }

    private func renewSessionIfValid() -> Promise<Void> {
        guard DataManager.shared.isLoggedIn else { return Promise(()) }
        Imap.shared.setup()
        return Imap.shared.renewSession()
    }

    private func chooseView(window: UIWindow) {
        if !DataManager.shared.isLoggedIn {
            window.rootViewController = MainNavigationController(rootViewController: SignInViewController())
        } else if DataManager.shared.isSetupFinished {
            window.rootViewController = SideMenuNavigationController()
        } else {
            window.rootViewController = MainNavigationController(rootViewController: SetupViewController())
        }
    }

}
