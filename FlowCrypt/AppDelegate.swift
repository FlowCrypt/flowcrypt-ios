//
//  AppDelegate.swift
//  FlowCrypt
//

import AppAuth
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var googleAuthSession: OIDExternalUserAgentSession?
    let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
