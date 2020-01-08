//
//  UITestHelper.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import XCTest

let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")

extension XCTest {
    func wait(_ time: TimeInterval) {
        _ = XCTWaiter().wait(for: [XCTestExpectation(description: "dummy-expectation")], timeout: time)
    }

    func wait(for element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    func waitForAny(of elements: [XCUIElement], timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate { (object, _) -> Bool in
            guard let elements = object as? [XCUIElement] else { return false }
            return elements.reduce(false) { $0 || $1.exists }
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: elements)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

final class Springboard {

    static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    /**
     Terminate and delete the app via springboard
     */
    class func deleteApp() {
//        XCUIApplication().terminate()
//
//        springboard.activate()
//        
//        let icons = springboard.icons.matching(identifier: "FlowCrypt")
//        let icon = icons.firstMatch
//        if !icon.exists { return }
//        
//        XCUIDevice.shared
//        
//        icon.press(forDuration: 1.3)
//
//        springboard.buttons["Rearrange Apps"].tap()
//
//        Thread.sleep(forTimeInterval: 1)
//
//        icon.buttons["DeleteButton"].tap()
//
//        let deleteButton = springboard.alerts.buttons["Delete"].firstMatch
//        XCTAssert(deleteButton.waitForExistence(timeout: 3))
//        deleteButton.tap()
    }

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
