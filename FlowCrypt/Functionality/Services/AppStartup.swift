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
    static var shared: AppStartup = AppStartup()

    let googleService: GoogleServiceType

    private init(
        googleService: GoogleServiceType = GoogleService()
    ) {
        self.googleService = googleService
    }

    public func initializeApp(window: UIWindow) {
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
        try await(renewSessionIfValid())
    }

    private func renewSessionIfValid() -> Promise<Void> {
        Imap.shared.renewSession()
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
