//
//  AppDelegate.swift
//  FlowCrypt
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    private lazy var appUrlHandler = AppUrlHandler()

    let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GlobalRouter().proceed()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        appUrlHandler.handle(app, open: url, options: options)
    }
}
