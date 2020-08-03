//
//  AppDelegate.swift
//  FlowCrypt
//

import UIKit
import AsyncDisplayKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    private lazy var appUrlHandler = AppUrlHandler()

    let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)
    let t = ContactsProvider()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        disableHardwareKeyboardOnSimulator()
        GlobalRouter().proceed()

        t.searchContact(with: "")
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
            .filter { $0.responds(to: setHardwareLayout) }
            .forEach { $0.perform(setHardwareLayout, with: nil) }
    #endif
}
