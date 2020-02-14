//
//  AppDelegate.swift
//  FlowCrypt
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    private lazy var appUrlHandler = AppUrlHandler()

    let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)

    func application(_ aplication: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        disableHardwareKeyboardOnSimulator()
        AppStartup().initializeApp(window: window)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appUrlHandler.handle(app, open: url, options: options)
    }
}

private func disableHardwareKeyboardOnSimulator() {
    #if targetEnvironment(simulator)
    let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
    UITextInputMode.activeInputModes
        .filter({ $0.responds(to: setHardwareLayout) })
        .forEach { $0.perform(setHardwareLayout, with: nil) }
    #endif
}
