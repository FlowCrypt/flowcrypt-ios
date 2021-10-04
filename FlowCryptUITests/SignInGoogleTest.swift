//
//  SigninGoogleTest.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import XCTest

class SignInGoogleTest: XCTestCase, AppTest {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false

        app = XCUIApplicationBuilder()
            .setupRegion()
            .build()
            .launched()

        logger.logInfo("Wait for launch")
        wait(10)
    }

    private var gmailAlert: XCUIElement {
        Springboard.springboard.alerts.element
    }

    private var gmailLoginButton: XCUIElement {
        app.tables.buttons["Continue with Gmail"]
    }

    private var findTextFieldForGmailWebView: XCUIElement? {
        logger.logInfo("Try to find text field for gmail web view")
        return app.webViews.textFields.firstMatch
    }

    func test_1_successful_login() {
        logOutIfNeeded()
        wait(2)
        startGmailLoginFlow()
        wait(5)

        let user = UserCredentials.gmailDev

        enterUserCredentials(for: user)
        wait(5)
        enterUserDevCredentials(for: user)
        wait(5)
    }

    private func startGmailLoginFlow() {
        // Tap on Gmail login
        gmailLoginButton.tap()
        wait(5)

        // Wait for user alert and continue
        guard gmailAlert.exists else {
            assertionFailure("Gmail alert is missing")
            return
        }

        logger.logInfo("Gmail alert is on the screen")

        gmailAlert.buttons["Continue"].tap()
        wait(3)
    }

    private func enterUserCredentials(for user: UserCredentials) {
        // Try to find first text field in gmail web view
        logger.logInfo("Try to find text field for gmail web view")
        let textField = app.webViews.textFields.firstMatch
        guard textField.exists else {
            assertionFailure("Can't find text field in Gmail Web view")
            return
        }
        textField.tap()
        wait(0.2)

        textField.typeText(user.email)
        goKeyboardButton.tap()
    }

    private func enterUserDevCredentials(for user: UserCredentials) {
        let mainWebView = app.webViews.otherElements["main"]

        let userNameTextField = mainWebView.children(matching: .textField).element
        userNameTextField.tap()
        userNameTextField.typeText(user.email)

        app.toolbars.matching(identifier: "Toolbar").buttons["Next"].tap()
        app.typeText(user.password)

        wait(2)
        goKeyboardButton.tap()
        wait(3)
    }
}

// Temporary disabled. Wait for https://github.com/FlowCrypt/flowcrypt-ios/issues/408
extension SignInGoogleTest {
    //        // enter password
    //        let passwordTextField = webView.secureTextFields.firstMatch
    //        passwordTextField.tap()
    //        passwordTextField.typeText(user.password)
    //        let goButton = goKeyboardButton
    //        XCTAssert(goButton.exists, "Password keyboard button")
    //        goButton.tap()
    //
    //        wait(5)
    //
    //        XCTAssert(app.tables.firstMatch.exists, "Table does not exist")
    //
    //        // MARK: - Wrong pass phrase
    //        // enter wrong pass phrase and tap enter
    //        let button = goKeyboardButton
    //
    //        app.typeText(user.pass + "wrong")
    //        button.tap()
    //
    //        wait(0.2)
    //        let errorAlert = app.alerts["Error"]
    //        XCTAssert(errorAlert.exists, "Error alert is missing after entering wrong pass phrase")
    //        errorAlert.scrollViews.otherElements.buttons["OK"].tap()
    //        wait(0.2)
    //        app.tables.secureTextFields.firstMatch.tap()
    //
    //        // MARK: - Correct pass phrase
    //        // enter correct pass phrase and tap enter
    //        if button.exists {
    //            app.typeText(user.pass)
    //            button.tap()
    //        } else {
    //            _ = app.keys[user.pass + "\n"]
    //        }
    //        wait(1)
    //
    //        XCTAssert(app.navigationBars["Inbox"].exists, "Could not login")
    //
    //        // MARK: - Send message
    //        sendMessage(to: user.email)
    //        XCTAssert(app.navigationBars["Inbox"].exists, "Failed state after Sending message")
    //
    //        // MARK: - Check in sent mail box
    //        menuButton.tap()
    //        tapOnMenu(folder: "Sent Mail")
    //        wait(3)
    //
    //        app.tables.cells.otherElements.staticTexts[user.email].firstMatch.tap()
    //        wait(5)
    //
    //        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
    //        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
    //        XCTAssert(app.tables.staticTexts["Some text"].exists, "Wrong text")
    //    }
    //
    //    func test_4_move_msg_to_trash() {
    //        // Move msg to Trash
    //        wait(2)
    //        tapOnCell()
    //
    //        app.navigationBars.buttons["Delete"].tap()
    //        wait(1)
    //
    //        // Verify in Trash
    //        menuButton.tap()
    //        tapOnMenu(folder: "Trash")
    //        XCTAssert(app.tables.cells.otherElements.staticTexts[user.email].exists, "There is no message in trash")
    //
    //        tapOnCell()
    //        let buttons = app.navigationBars.buttons
    //        let backButton = buttons["arrow left c"]
    //
    //        // Verify buttons in Trash folder
    //        XCTAssert(buttons["Delete"].exists, "Navigation bar should contain delete button")
    //        XCTAssert(buttons["help icn"].exists, "Navigation bar should contain help button")
    //        XCTAssert(backButton.exists, "Navigation bar should contain back button")
    //        XCTAssert(buttons.count == 3, "")
    //
    //        // Open following first msg
    //        backButton.tap()
    //        menuButton.tap()
    //        tapOnMenu(folder: "Inbox")
    //
    //        tapOnCell()
    //    }
    //
    //    func test_5_move_msg_to_archive() {
    //        wait(2)
    //        sendMessage(to: user.email)
    //        app.tables.cells.otherElements.staticTexts[user.email].firstMatch.tap()
    //        app.navigationBars.buttons["archive"].tap()
    //        wait(2)
    //        XCTAssert(app.navigationBars["Inbox"].exists, "Failed in sending message to archive")
    //
    //        menuButton.tap()
    //        tapOnMenu(folder: "All Mail")
    //        wait(1)
    //
    //        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
    //        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
    //    }
    //
    //    func test_6_send_message_no_pub_key() {
    //        wait(2)
    //        sendMessage(to: "flowcrypt.nopubkey@gmail.com")
    //        wait(3)
    //        let errorAlert = app.alerts["Error"]
    //        XCTAssert(errorAlert.exists)
    //    }
}
