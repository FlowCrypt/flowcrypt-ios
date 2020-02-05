//
//  XCUIApplicationBuilder.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import XCTest

struct XCUIApplicationBuilder {
    private let app: XCUIApplication
    
    init() {
        app = XCUIApplication()
        app.launchArguments.append("--is-ui-test")
        #if targetEnvironment(simulator)
        // Disable hardware keyboards.
        let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
        UITextInputMode.activeInputModes
            // Filter `UIKeyboardInputMode`s.
            .filter({ $0.responds(to: setHardwareLayout) })
            .forEach { $0.perform(setHardwareLayout, with: nil) }
        #endif
        
    }
    
    func reset() -> XCUIApplicationBuilder {
        app.launchArguments.append(AppReset.reset.rawValue)
        return self
    }

    func setupRegion() -> XCUIApplicationBuilder {
//        app.launchArguments += ["-AppleLanguages", "(en-US)"]
//        app.launchArguments += ["-AppleLocale", "en-US"]
        app.launchArguments += ProcessInfo().arguments
        
        return self
    }
    
    func build() -> XCUIApplication {
        app
    }
    
    
}

extension XCUIApplication {
    func launched() -> XCUIApplication {
        launch()
        return self
    }
}
