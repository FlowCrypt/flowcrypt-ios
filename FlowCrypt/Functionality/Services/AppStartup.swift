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
    private enum EntryPoint {
        case signIn, setupFlow(UserId), mainFlow
    }

    func initializeApp(window: UIWindow, session: SessionType?) {
        DispatchQueue.promises = .global()
        window.rootViewController = BootstrapViewController()
        window.makeKeyAndVisible()
        Promise<Void> {
            self.setupCore()
            try self.setupMigrationIfNeeded()
            try self.setupSession()
        }.then(on: .main) {
            self.chooseView(for: window, session: session)
        }.catch(on: .main) { error in
            self.showErrorAlert(with: error, on: window, session: session)
        }
    }

    private func setupCore() {
        Core.shared.startInBackgroundIfNotAlreadyRunning()
    }

    private func setupMigrationIfNeeded() throws {
        try awaitPromise(DataService.shared.performMigrationIfNeeded())
    }

    private func setupSession() throws {
        try awaitPromise(renewSessionIfValid())
    }

    private func renewSessionIfValid() -> Promise<Void> {
        guard DataService.shared.currentAuthType != nil else {
            return Promise(())
        }
        return MailProvider.shared.sessionProvider.renewSession()
    }

    private func chooseView(for window: UIWindow, session: SessionType?) {
        guard let entryPoint = entryPointForUser(session: session) else {
            assertionFailure("Internal error, can't choose desired entry point")
            return
        }

//        switch entryPoint {
//        case .mainFlow:
//            window.rootViewController = SideMenuNavigationController()
//        case .signIn:
//            window.rootViewController = MainNavigationController(rootViewController: SignInViewController())
//        case .setupFlow(let userId):
            // TODO: - ANTON
//            let setupViewController = SetupInitialViewController(user: userId)
        let setupViewController = SetupInitialViewController(user: .init(email: "flow.test.anton@gmail.com", name: "Name"))
            window.rootViewController = MainNavigationController(rootViewController: setupViewController)
//        }
    }

    private func entryPointForUser(session: SessionType?) -> EntryPoint? {
        if !DataService.shared.isLoggedIn {
            return .signIn
        } else if DataService.shared.isSetupFinished {
            return .mainFlow
        } else if let session = session, let userId = makeUserIdForSetup(session: session) {
            return .setupFlow(userId)
        } else {
            return .signIn
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
