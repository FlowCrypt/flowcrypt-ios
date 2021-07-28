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
        let plusButton = app.buttons["tap"]

        if plusButton.exists {
            plusButton.tap()
        } else {
            // for iPhone X
            XCUIDevice.shared.orientation = .landscapeLeft
            app.buttons["+"].tap()
            XCUIDevice.shared.orientation = .portrait
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

    func login(_ user: UserCredentials) {
        logger.logInfo("Login with \(user.email)")
        
        // other account
        logOutIfNeeded()
        wait(0.3)

        logger.logInfo("Use other email provider")
        let otherEmailButton = app.tables.buttons["Other email provider"]
        otherEmailButton.tap()

        logger.logInfo("Fill all user credentials")
        // email
        let emailTextField = app.tables.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText(user.email)

        // password
        let passwordTextField = app.tables.secureTextFields["Password"]
        passwordTextField.tap()
        passwordTextField.typeText(user.password)

        // connect
        passwordTextField.swipeUp()
        app.tables.buttons["Connect"].tap()
        
        logger.logInfo("Try to connect")
        wait(10)
    }
    
    func logOutIfNeeded() {
        logger.logInfo("Log out if needed")
       
        // Check which screen we are now
        guard menuButton.exists else {
            logger.logInfo("Already logged out")
            return
        }
        
        if menuButton.exists {
            logger.logInfo("User is logged in. Try to log out")
            menuButton.tap()
            tapOnMenu(folder: "Log out")
        } else {
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
