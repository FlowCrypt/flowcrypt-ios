//
//  AppTestHelper.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
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

    var menuButton: XCUIElement {
        app.navigationBars.buttons["menu icn"]
    }

    var passPhraseTextField: XCUIElement {
        app.tables.secureTextFields["Enter your pass phrase"]
    }

    var navigationBackButton: XCUIElement {
        app.navigationBars.buttons["arrow left c"]
    }

    var setupUseAnotherAccount: XCUIElement {
        app.tables.buttons["Use Another Account"]
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
        let plusButton = app.buttons["+"]

        if plusButton.exists {
            plusButton.tap()
        } else {
            logger.logError("+ does not exist")
        }
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

    func tapOnHomeButton() {
        XCUIDevice.shared.press(.home)
    }

    func logOutIfNeeded() {
        logger.logInfo("Log out if needed")

        if menuButton.exists {
            logger.logInfo("User is logged in. Try to log out")
            menuButton.tap()
            tapOnMenu(folder: "Log out")
        } else {
            logger.logInfo("No menu button")

            let otherAccountButton = app.tables.buttons["Use Another Account"]
            if otherAccountButton.exists {
                logger.logInfo("Try to use another account")
                otherAccountButton.tap()
            } else {
                logger.logInfo("User is not logged in")
            }
        }
    }
}
