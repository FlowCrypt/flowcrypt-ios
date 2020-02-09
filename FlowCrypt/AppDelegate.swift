//
//  AppDelegate.swift
//  FlowCrypt
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    let assembley = RootAssembley()
    private lazy var appUrlHandler = AppUrlHandler()

    let launchFlowController = LaunchFlowController.default

    let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)

    func application(_ aplication: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        launchFlowController.startFlow(
            with: LaunchContext(
                window: window,
                aplication: aplication,
                launchOptions: options
            )
        )
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appUrlHandler.handle(app, open: url, options: options)
    }
}
