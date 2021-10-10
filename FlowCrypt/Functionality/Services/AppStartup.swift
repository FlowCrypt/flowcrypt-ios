//
//  StartupChecks.swift
//  FlowCrypt
//
//  Created by luke on 13/2/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Promises
import UIKit

private let logger = Logger.nested("AppStart")

struct AppStartup {
    private enum EntryPoint {
        case signIn, setupFlow(UserId), mainFlow
    }

    func initializeApp(window: UIWindow, session: SessionType?) {
        logger.logInfo("Initialize application with session \(session.debugDescription)")

        DispatchQueue.promises = .global()
        window.rootViewController = BootstrapViewController()
        window.makeKeyAndVisible()

        Promise<Void> {
            try awaitPromise(self.setupCore())
            try self.setupMigrationIfNeeded()
            try self.setupSession()
            try self.getUserOrgRulesIfNeeded()
        }.then(on: .main) {
            self.chooseView(for: window, session: session)
        }.catch(on: .main) { error in
            self.showErrorAlert(with: error, on: window, session: session)
        }
    }

    private func setupCore() -> Promise<Void> {
        Promise { resolve, _ in
            logger.logInfo("Setup Core")
            Core.shared.startInBackgroundIfNotAlreadyRunning {
                resolve(())
            }
        }
    }

    private func setupMigrationIfNeeded() throws {
        logger.logInfo("Setup Migration")
        try awaitPromise(DataService.shared.performMigrationIfNeeded())
    }

    private func setupSession() throws {
        logger.logInfo("Setup Session")
        try awaitPromise(renewSessionIfValid())
    }

    private func renewSessionIfValid() -> Promise<Void> {
        guard DataService.shared.currentAuthType != nil else {
            return Promise(())
        }
        return MailProvider.shared.sessionProvider.renewSession()
    }

    private func chooseView(for window: UIWindow, session: SessionType?) {
        let entryPoint = entryPointForUser(session: session)

        let viewController: UIViewController

        switch entryPoint {
        case .mainFlow:
            viewController = SideMenuNavigationController()
        case .signIn:
            viewController = MainNavigationController(rootViewController: SignInViewController())
        case .setupFlow(let userId):
            let setupViewController = SetupInitialViewController(user: userId)
            viewController = MainNavigationController(rootViewController: setupViewController)
        }

        window.rootViewController = viewController
    }

    private func entryPointForUser(session: SessionType?) -> EntryPoint {
        if !DataService.shared.isLoggedIn {
            logger.logInfo("User is not logged in -> signIn")
            return .signIn
        } else if DataService.shared.isSetupFinished {
            logger.logInfo("Setup finished -> mainFlow")
            return .mainFlow
        } else if let session = session, let userId = makeUserIdForSetup(session: session) {
            logger.logInfo("User with session \(session) -> setupFlow")
            return .setupFlow(userId)
        } else {
            logger.logInfo("User us not signed in -> mainFlow")
            return .signIn
        }
    }

    private func getUserOrgRulesIfNeeded() throws {
        if DataService.shared.isLoggedIn {
            let service = OrganisationalRulesService()
            _ = try awaitPromise(service.fetchOrganisationalRulesForCurrentUser())
        }
    }

    private func makeUserIdForSetup(session: SessionType) -> UserId? {
        guard let currentUser = DataService.shared.currentUser else {
            Logger.logInfo("Can't create user id for setup")
            return nil
        }

        var userId = UserId(email: currentUser.email, name: currentUser.name)

        switch session {
        case let .google(email, name, _):
            guard currentUser.email != email else {
                logger.logInfo("UserId = current user id")
                return userId
            }
            logger.logInfo("UserId = google user id")
            userId = UserId(email: email, name: name)
        case let .session(userObject):
            guard userObject.email != currentUser.email else {
                Logger.logInfo("UserId = current user id")
                return userId
            }
            Logger.logInfo("UserId = session user id")
            userId = UserId(email: userObject.email, name: userObject.name)
        }

        return userId
    }

    private func showErrorAlert(with error: Error, on window: UIWindow, session: SessionType?) {
        let alert = UIAlertController(title: "Startup Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        let retry = UIAlertAction(title: "Retry", style: .default) { _ in
            self.initializeApp(window: window, session: session)
        }
        alert.addAction(retry)
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
