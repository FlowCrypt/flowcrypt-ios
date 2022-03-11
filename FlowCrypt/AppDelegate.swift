//
//  AppDelegate.swift
//  FlowCrypt
//

import AppAuth
import UIKit
import GTMAppAuth
import FlowCryptCommon
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AppDelegateGoogleSesssionContainer {
    var blurViewController: BlurViewController?
    var googleAuthSession: OIDExternalUserAgentSession?
    let window = UIWindow(frame: UIScreen.main.bounds)
    private var cancellable = Set<AnyCancellable>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if application.isRunningTests {
            return true
        }
        // Avoid race condition where the app might try to access keychain data before the device has decrypted it
        guard UIApplication.shared.isProtectedDataAvailable else {
            NotificationCenter
                 .default
                 .publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)
                 .first()
                 .sink { _ in
                     GlobalRouter().proceed()
                 }.store(in: &cancellable)
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
        cancellable.forEach { $0.cancel() }
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
