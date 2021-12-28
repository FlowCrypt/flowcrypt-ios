//
//  AppDelegate.swift
//  FlowCrypt
//

import AppAuth
import UIKit
import GTMAppAuth
import FlowCryptCommon

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AppDelegateGoogleSesssionContainer {
    var blurViewController: BlurViewController?
    var googleAuthSession: OIDExternalUserAgentSession?
    let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if application.isRunningTests {
            return true
        }
        GlobalRouter().proceed()
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
