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
        }.catch(on: .main) { error in
            self.showErrorAlert(with: error, on: window)
            log("AppStartup", error: error, res: nil, start: start)
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
        guard DataService.shared.currentAuthType != nil else {
            return Promise(())
        }
        return MailProvider.shared.sessionProvider.renewSession()
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

    private func showErrorAlert(with error: Error, on window: UIWindow) {
        let alert = UIAlertController(title: "Startup Error", message: "\(error)", preferredStyle: .alert)
        let retry = UIAlertAction(title: "Retry", style: .default) { _ in
            self.initializeApp(window: window)
        }
        alert.addAction(retry)
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
