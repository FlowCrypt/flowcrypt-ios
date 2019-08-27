//
//  AppDelegate.swift
//  FlowCrypt
//

import UIKit
import GoogleSignIn
import RealmSwift
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let googleApi = GoogleApi.shared
    private let assembley = RootAssembley()
    private lazy var appUrlHandler = AppUrlHandler(googleApi: GIDSignIn.sharedInstance())

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        assembley.assemble()
        window = UIWindow(frame: UIScreen.main.bounds)
        assembley.setup(window: window)
        return assembley.startFlow()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appUrlHandler.handle(app, open: url, options: options)
    }
}

