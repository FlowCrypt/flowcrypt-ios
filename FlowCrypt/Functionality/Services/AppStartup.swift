//
//  StartupChecks.swift
//  FlowCrypt
//
//  Created by luke on 13/2/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

private let logger = Logger.nested("AppStart")

struct AppStartup {
    private enum EntryPoint {
        case signIn, setupFlow(UserId), mainFlow
    }

    func initializeApp(window: UIWindow, session: SessionType?) {
        logger.logInfo("Initialize application with session \(session.debugDescription)")

        window.rootViewController = BootstrapViewController()
        window.makeKeyAndVisible()

        Task {
            do {
                await setupCore()
                try await DataService.shared.performMigrationIfNeeded()
                try await setupSession()
                try await getUserOrgRulesIfNeeded()
                await chooseView(for: window, session: session)
            } catch {
                await showErrorAlert(with: error, on: window, session: session)
            }
        }
    }

    private func setupCore() async {
        logger.logInfo("Setup Core")
        await Core.shared.startIfNotAlreadyRunning()
    }

    private func setupSession() async throws {
        logger.logInfo("Setup Session")
        try await renewSessionIfValid()
    }

    private func renewSessionIfValid() async throws {
        guard DataService.shared.currentAuthType != nil else {
            return
        }
        return try await MailProvider.shared.sessionProvider.renewSession()
    }

    @MainActor
    private func chooseView(for window: UIWindow, session: SessionType?) {
        let entryPoint = entryPointForUser(session: session)

        let viewController: UIViewController

        switch entryPoint {
        case .mainFlow:
            let contentViewController = InboxViewContainerController()
            viewController = SideMenuNavigationController(contentViewController: contentViewController)
        case .signIn:
            viewController = MainNavigationController(rootViewController: SignInViewController())
        case .setupFlow(let userId):
            let setupViewController = SetupInitialViewController(user: userId)
            viewController = MainNavigationController(rootViewController: setupViewController)
        }

        window.rootViewController = viewController
    }

    private func entryPointForUser(session: SessionType?) -> EntryPoint {
        let dataService = DataService.shared
        if !dataService.isLoggedIn {
            logger.logInfo("User is not logged in -> signIn")
            return .signIn
        } else if dataService.isSetupFinished {
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

    private func getUserOrgRulesIfNeeded() async throws {
        if DataService.shared.isLoggedIn {
            _ = try await ClientConfigurationService().fetchForCurrentUser()
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

    @MainActor
    private func showErrorAlert(with error: Error, on window: UIWindow, session: SessionType?) {
        let alert = UIAlertController(title: "Startup Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        let retry = UIAlertAction(title: "Retry", style: .default) { _ in
            self.initializeApp(window: window, session: session)
        }
        alert.addAction(retry)
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
