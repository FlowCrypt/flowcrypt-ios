//
//  UIApplicationExtension.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 25/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

extension UIApplication {

    var keyWindow: UIWindow? {
        // Get connected scenes
        UIApplication.shared.connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }

    var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }
}
