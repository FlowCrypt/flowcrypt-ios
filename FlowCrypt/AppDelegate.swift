//
//  AppDelegate.swift
//  FlowCrypt
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    let assembley = RootAssembley()
    private lazy var appUrlHandler = AppUrlHandler()

    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        assembley.assemble()
        window = assembley.setupWindow()
        return assembley.startFlow()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appUrlHandler.handle(app, open: url, options: options)
    }
}
