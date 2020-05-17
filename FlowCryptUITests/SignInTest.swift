//
//  SignInViewControllerTest.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest

class SignInTest: XCTestCase {
    var app: XCUIApplication!
    let user = UserCredentials.main

    override func setUp() {
        continueAfterFailure = false

        app = XCUIApplicationBuilder()
            .setupRegion()
            .build()
            .launched()
    }

    func test_cancel_login() {
        app.tables.buttons["gmail"].tap()
        wait(1)

        let cancelButton = gmailAlert.buttons["Cancel"]
        XCTAssert(cancelButton.exists, "Cancel in Alert doesn't exist")
        cancelButton.tap()

        wait(1)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists)
    }

    func test_gmail_login() {
        let user = UserCredentials.main

        // tap on gmail button

        // MARK: - Google Login

        app.tables.buttons["gmail"].tap()
        let signInAlert = gmailAlert

        wait(1)

        // continue on alert
        let continueButton = signInAlert.buttons["Continue"]
        XCTAssert(continueButton.exists, "ContinueButton in Alert doesn't exist")
        continueButton.tap()

        wait(5)

        // enter user name
        let webView = app.webViews
        let textField = webView.textFields.firstMatch
        wait(1)

        textField.tap()

        textField.typeText(user.email)
        let returnButton = goKeyboardButton
        XCTAssert(returnButton.exists, "User keyboard button")
        returnButton.tap()

        wait(1)

        // enter password
        let passwordTextField = webView.secureTextFields.firstMatch
        passwordTextField.tap()
        passwordTextField.typeText(user.password)
        let goButton = goKeyboardButton
        XCTAssert(goButton.exists, "Password keyboard button")
        goButton.tap()

        wait(5)

        XCTAssert(app.tables.firstMatch.exists, "Table does not exist")

        // MARK: - Wrong pass phrase

        // enter wrong pass phrase and tap enter
        let button = goKeyboardButton

        app.typeText(user.pass + "wrong")
        button.tap()

        wait(0.2)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists, "Error alert is missing after entering wrong pass phrase")
        errorAlert.scrollViews.otherElements.buttons["OK"].tap()
        wait(0.2)
        app.tables.secureTextFields.firstMatch.tap()

        // MARK: - Correct pass phrase

        // enter correct pass phrase and tap enter
        if button.exists {
            app.typeText(user.pass)
            button.tap()
        } else {
            _ = app.keys[user.pass + "\n"]
        }
        wait(1)

        XCTAssert(app.navigationBars["Inbox"].exists, "Could not login")

        // MARK: - Send message

        sendMessage(to: user.email)
        XCTAssert(app.navigationBars["Inbox"].exists, "Failed state after Sending message")

        // MARK: - Check in sent mail box

        menuButton.tap()
        tapOnMenu(folder: "Sent Mail")
        wait(3)

        app.tables.cells.otherElements.staticTexts[user.email].firstMatch.tap()
        wait(5)

        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
        XCTAssert(app.tables.staticTexts["Some text"].exists, "Wrong text")
    }

    func test_move_msg_to_trash() {
        // Move msg to Trash
        wait(2)
        tapOnCell()

        app.navigationBars.buttons["Delete"].tap()
        wait(1)

        // Verify in Trash
        menuButton.tap()
        tapOnMenu(folder: "Trash")
        XCTAssert(app.tables.cells.otherElements.staticTexts[user.email].exists, "There is no message in trash")

        tapOnCell()
        let buttons = app.navigationBars.buttons
        let backButton = buttons["arrow left c"]

        // Verify buttons in Trash folder
        XCTAssert(buttons["Delete"].exists, "Navigation bar should contain delete button")
        XCTAssert(buttons["help icn"].exists, "Navigation bar should contain help button")
        XCTAssert(backButton.exists, "Navigation bar should contain back button")
        XCTAssert(buttons.count == 3, "")

        // Open following first msg
        backButton.tap()
        menuButton.tap()
        tapOnMenu(folder: "Inbox")

        tapOnCell()
    }

    func test_move_msg_to_archive() {
        wait(2)
        sendMessage(to: user.email)
        app.tables.cells.otherElements.staticTexts[user.email].firstMatch.tap()
        app.navigationBars.buttons["archive"].tap()
        wait(2)
        XCTAssert(app.navigationBars["Inbox"].exists, "Failed in sending message to archive")

        menuButton.tap()
        tapOnMenu(folder: "All Mail")
        wait(1)

        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
    }

    func test_send_message_no_pub_key() {
        wait(2)
        sendMessage(to: "flowcrypt.nopubkey@gmail.com")
        wait(3)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists)
    }
}

extension SignInTest {
    private var cells: [XCUIElement] {
        app.tables
            .cells
            .allElementsBoundByIndex
            .filter { $0.frame.origin.x >= 0 }
            .sorted(by: { $0.frame.origin.x > $1.frame.origin.x })
    }

    private var goKeyboardButton: XCUIElement {
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

    private var gmailAlert: XCUIElement {
        Springboard.springboard.alerts.element
    }

    private var menuButton: XCUIElement {
        app.navigationBars.buttons["menu icn"]
    }
}

extension SignInTest {
    private func sendMessage(to recipient: String) {
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

    private func tapOnCompose() {
        app.buttons["+"].tap()
        wait(0.2)
    }

    private func tapOnCell() {
        cells.first?.tap()
        wait(0.5)
    }

    private func tapOnMenu(folder: String) {
        app.tables.staticTexts[folder].tap()
        wait(1)
    }
}
