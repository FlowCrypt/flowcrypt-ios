//
//  AppTestHelper.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import XCTest

protocol AppTest {
    var app: XCUIApplication! { get set }
}

// MARK: - Helpers
extension AppTest {
    var cells: [XCUIElement] {
        app.tables
            .cells
            .allElementsBoundByIndex
            .filter { $0.frame.origin.x >= 0 }
            .sorted(by: { $0.frame.origin.x > $1.frame.origin.x })
    }

    var goKeyboardButton: XCUIElement {
        if app.buttons["return"].exists {
            return app.buttons["return"]
        }
        if app.buttons["Return"].exists {
            return app.buttons["Return"]
        }
        if app.buttons["go"].exists {
            return app.buttons["go"]
        }

        return app.buttons["Go"]
    }

    var gmailAlert: XCUIElement {
        Springboard.springboard.alerts.element
    }

    var menuButton: XCUIElement {
        app.navigationBars.buttons["menu icn"]
    }

    var passPhraseTextField: XCUIElement {
        app.tables.secureTextFields["Enter your pass phrase"]
    }
}

// MARK: - Actions
extension AppTest {
    func sendMessage(to recipient: String ) {
        tapOnCompose()
        app.typeText(recipient)
        app.tables.textFields["Subject"].tap()

        app.tables.textFields["Subject"].tap()
        app.typeText("Some Subject")

        goKeyboardButton.tap()
        app.typeText("Some text")
        app.navigationBars["Inbox"].buttons["android send"].tap()
        wait(5)
    }

    func tapOnCompose() {
        app.buttons["+"].tap()
        wait(0.2)
    }

    func tapOnCell() {
        cells.first?.tap()
        wait(0.5)
    }

    func tapOnMenu(folder: String) {
        app.tables.staticTexts[folder].tap()
        wait(1)
    }

    func tapOnGoButton() {
        let button = goKeyboardButton
        if button.exists {
            button.tap()
        } else {
            _ = app.keys["\n"]
        }
    }
}
