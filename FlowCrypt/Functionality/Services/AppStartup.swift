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

    private let appContext: AppContext

    init(appContext: AppContext) {
        self.appContext = appContext
    }

    @MainActor
    func initializeApp(window: UIWindow) {
        logger.logInfo("Initialize application with session \(appContext.session.debugDescription)")

        Task {
            window.rootViewController = BootstrapViewController()
            window.makeKeyAndVisible()

            do {
                await setupCore()
                try await appContext.dataService.performMigrationIfNeeded()
                try await setupSession()
                try await getUserOrgRulesIfNeeded()
                chooseView(for: window)
            } catch {
                showErrorAlert(of: error, on: window)
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

    /// todo - refactor so that it doesn't need getOptionalMailProvider
    private func renewSessionIfValid() async throws {
        guard let mailProvider = await appContext.getOptionalMailProvider() else {
            return
        }
        return try await mailProvider.sessionProvider.renewSession()
    }

    @MainActor
    private func chooseView(for window: UIWindow) {
        let entryPoint = entryPointForUser()

        let viewController: UIViewController

        switch entryPoint {
        case .mainFlow:
            let appContextWithUser = appContext.withSession(appContext.session)
            let contentViewController = InboxViewContainerController(appContext: appContextWithUser)
            viewController = SideMenuNavigationController(
                appContext: appContextWithUser,
                contentViewController: contentViewController
            )
        case .signIn:
            viewController = MainNavigationController(rootViewController: SignInViewController(appContext: appContext))
        case .setupFlow(let userId):
            let setupViewController = SetupInitialViewController(appContext: appContext, user: userId)
            viewController = MainNavigationController(rootViewController: setupViewController)
        }

        window.rootViewController = viewController
    }

    private func entryPointForUser() -> EntryPoint {
        if !appContext.dataService.isLoggedIn {
            logger.logInfo("User is not logged in -> signIn")
            return .signIn
        } else if appContext.dataService.isSetupFinished, appContext.dataService.currentUser != nil {
            logger.logInfo("Setup finished -> mainFlow")
            return .mainFlow
        } else if let session = appContext.session, let userId = makeUserIdForSetup(session: session) {
            logger.logInfo("User with session \(session) -> setupFlow")
            return .setupFlow(userId)
        } else {
            logger.logInfo("User us not signed in -> mainFlow")
            return .signIn
        }
    }

    private func getUserOrgRulesIfNeeded() async throws {
        guard let currentUser = appContext.dataService.currentUser else {
            return
        }
        if appContext.dataService.isLoggedIn {
            _ = try await appContext.clientConfigurationService.fetch(for: currentUser)
        }
    }

    private func makeUserIdForSetup(session: SessionType) -> UserId? {
        guard let currentUser = appContext.dataService.currentUser else {
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
    private func showErrorAlert(of error: Error, on window: UIWindow) {
        let alert = UIAlertController(
            title: "Startup Error",
            message: "\(error.localizedDescription)",
            preferredStyle: .alert
        )
        let retry = UIAlertAction(title: "Retry", style: .default) { _ in
            self.initializeApp(window: window)
        }
        alert.addAction(retry)
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
