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
        disableHardwareKeyboard()
        assembley.assemble()
        window = assembley.setupWindow()
        return assembley.startFlow()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appUrlHandler.handle(app, open: url, options: options)
    }
}

private func disableHardwareKeyboard() {
    #if targetEnvironment(simulator)
    let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
    UITextInputMode.activeInputModes
        .filter({ $0.responds(to: setHardwareLayout) })
        .forEach { $0.perform(setHardwareLayout, with: nil) }
    #endif
}
