//
//  StartupChecks.swift
//  FlowCrypt
//
//  Created by luke on 13/2/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct AppStartup {
    let googleService: GoogleServiceType

    init(
        googleService: GoogleServiceType = GoogleService()
    ) {
        self.googleService = googleService
    }

    public func initializeApp(window: UIWindow) {
        #warning("Do not forget")

//        Imap.shared.setupSession()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            Imap.shared.fetchFolders()
//            .then { print($0) }
//            .catch { print($0) }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                       Imap.shared.fetchFolders()
//                       .then { print($0) }
//                       .catch { print($0) }
//                   }
//        }

        let start = DispatchTime.now()
        DispatchQueue.promises = .global()
        window.rootViewController = BootstrapViewController()
        window.makeKeyAndVisible()
        Promise<Void> {
            self.setupCore()
            try self.setUpAuthentication()
            try self.setupMigrationIfNeeded()
            try self.setupSession()
        }.then(on: .main) {
            self.chooseView(window: window)
            log("AppStartup", error: nil, res: nil, start: start)
        }.catch(on: .main) { err in
            let alert = UIAlertController(title: "Startup Error", message: "\(err)", preferredStyle: .alert)
            window.rootViewController?.present(alert, animated: true, completion: nil)
            log("AppStartup", error: err, res: nil, start: start)
        }
    }

    private func setupCore() {
        Core.shared.startInBackgroundIfNotAlreadyRunning()
    }

    private func setUpAuthentication() throws {
        try googleService.setUpAuthentication()
    }

    private func setupMigrationIfNeeded() throws {
        try await(DataService.shared.performMigrationIfNeeded())
    }

    private func setupSession() throws {
        try await(self.renewSessionIfValid())
    }

    private func renewSessionIfValid() -> Promise<Void> {
        guard DataService.shared.isLoggedIn else { return Promise(()) }
        Imap.shared.setupSession()
        return Imap.shared.renewSession()
    }

    private func chooseView(window: UIWindow) {
        if !DataService.shared.isLoggedIn {
            window.rootViewController = MainNavigationController(rootViewController: SignInViewController())
        } else if DataService.shared.isSetupFinished {
            window.rootViewController = SideMenuNavigationController()
        } else {
            window.rootViewController = MainNavigationController(rootViewController: SetupViewController())
        }
    }
}
