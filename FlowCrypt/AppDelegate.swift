//
//  AppDelegate.swift
//  FlowCrypt
//

import AppAuth
import UIKit
import Firebase

class AppDelegate: UIResponder, UIApplicationDelegate {
    var blurViewController: BlurViewController?
    var googleAuthSession: OIDExternalUserAgentSession?
    let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        if isRunningTests {
            return true
        }
        GlobalRouter().proceed()
        FirebaseApp.configure()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let authSession = googleAuthSession, authSession.resumeExternalUserAgentFlow(with: url) else {
            return false
        }
        googleAuthSession = nil
        return true
    }
}

extension AppDelegate: BlursTopView {
    func applicationWillResignActive(_ application: UIApplication) {
        if !isBlurViewShowing() {
            coverTopViewWithBlurView()
        }
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        if isBlurViewShowing() {
            removeBlurView()
        }
    }
}
