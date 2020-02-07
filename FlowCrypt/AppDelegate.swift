//
//  AppDelegate.swift
//  FlowCrypt
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    let assembley = RootAssembley()
    private lazy var appUrlHandler = AppUrlHandler()

    private let launchFlowController = LaunchFlowController.default

    var window: UIWindow?

    func application(_ aplication: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        assembley.assemble()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        // window = assembley.setupWindow()

        let launchContext = LaunchContext(
            window: window,
            aplication: aplication,
            launchOptions: options
        )

        return launchFlowController.startFlow(with: launchContext)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appUrlHandler.handle(app, open: url, options: options)
    }
}


























