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
    func initializeApp(window: UIWindow, session: SessionType?) {
        let start = DispatchTime.now()
        DispatchQueue.promises = .global()
        window.rootViewController = BootstrapViewController()
        window.makeKeyAndVisible()
        Promise<Void> {
            self.setupCore()
            try self.setupMigrationIfNeeded()
            try self.setupSession()
        }.then(on: .main) {
            self.chooseView(for: window, session: session)
            log("AppStartup", error: nil, res: nil, start: start)
        }.catch(on: .main) { error in
            self.showErrorAlert(with: error, on: window, session: session)
            log("AppStartup", error: error, res: nil, start: start)
        }
    }

    private func setupCore() {
        Core.shared.startInBackgroundIfNotAlreadyRunning()
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

    private func chooseView(for window: UIWindow, session: SessionType?) {
        if !DataService.shared.isLoggedIn {
            window.rootViewController = MainNavigationController(rootViewController: SignInViewController())
            return
        } else if DataService.shared.isSetupFinished {
            window.rootViewController = SideMenuNavigationController()
            return
        } else {
            guard let session = session, let userId = makeUserIdForSetup(session: session) else {
                assertionFailure("Internal error, can't start SetupViewController without session")
                return
            }
            let setupViewController = SetupViewController(user: userId)
            window.rootViewController = MainNavigationController(rootViewController: setupViewController)
        }
    }

    private func makeUserIdForSetup(session: SessionType) -> UserId? {
        guard let currentUser = DataService.shared.currentUser else {
            return nil
        }

        var userId = UserId(email: currentUser.email, name: currentUser.name)

        switch session {
        case let .google(email, name, _):
            guard currentUser.email != email else {
                return userId
            }
            userId = UserId(email: email, name: name)
        case let .session(userObject):
            guard userObject.email != currentUser.email else {
                return userId
            }
            userId = UserId(email: userObject.email, name: userObject.name)
        }

        return userId
    }

    private func showErrorAlert(with error: Error, on window: UIWindow, session: SessionType?) {
        let alert = UIAlertController(title: "Startup Error", message: "\(error)", preferredStyle: .alert)
        let retry = UIAlertAction(title: "Retry", style: .default) { _ in
            self.initializeApp(window: window, session: session)
        }
        alert.addAction(retry)
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
