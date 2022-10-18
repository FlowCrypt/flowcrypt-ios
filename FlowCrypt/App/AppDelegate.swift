//
//  AppDelegate.swift
//  FlowCrypt
//

import AppAuth
import GTMAppAuth
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AppDelegateGoogleSessionContainer {
    var blurViewController: BlurViewController?
    var googleAuthSession: OIDExternalUserAgentSession?
    let window = UIWindow(frame: UIScreen.main.bounds)
    private var waitingForProtectedDataCancellable = Set<AnyCancellable>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if application.isRunningTests {
            return true
        }
        // When trying to initialize storage before protected data is available,
        // existing storage may get corrupted due to a lost db encryption key.
        // See https://github.com/FlowCrypt/flowcrypt-ios/issues/1373
        guard UIApplication.shared.isProtectedDataAvailable else {
            NotificationCenter
                 .default
                 .publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)
                 .first()
                 .sink { _ in
                     GlobalRouter().proceed()
                 }.store(in: &waitingForProtectedDataCancellable)
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
        for cancellable in waitingForProtectedDataCancellable {
            cancellable.cancel()
        }
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
