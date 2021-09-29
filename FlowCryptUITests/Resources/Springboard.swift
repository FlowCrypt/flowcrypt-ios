//
//  Springboard.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 08/01/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import XCTest

final class Springboard {
    static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    class func resetSettings() {
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)

        // Wait some time for the animation end
        Thread.sleep(forTimeInterval: 0.5)
        settings.launch()

        settings.tables.staticTexts["General"].tap()
        settings.tables.staticTexts["Reset"].tap()
        settings.tables.staticTexts["Reset Location & Privacy"].tap()
        settings.buttons["Reset Warnings"].tap()
        settings.terminate()
    }

    class func resetSafari() {
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)

        // Wait some time for the animation end
        Thread.sleep(forTimeInterval: 0.5)
        settings.launch()

        settings.tables.staticTexts["Safari"].tap()
        settings.tables.staticTexts["Clear History and Website Data"].tap()
        settings.buttons["Clear History and Data"].tap()
        settings.terminate()
    }
}
