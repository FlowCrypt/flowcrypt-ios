//
//  UIApplicationExtensions.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 25/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public extension UIApplication {

    var currentWindow: UIWindow? {
        // Get connected scenes
        UIApplication.shared.connectedScenes
            // Keep only the first active, onscreen and visible `UIWindowScene`
            .first(where: { $0.activationState == .foregroundActive && $0 is UIWindowScene })
            // Get its associated windows
            .flatMap { $0 as? UIWindowScene }?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }

    var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }
}
