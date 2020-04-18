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
    private let googleUser = UserCredentials.main
    private let compatibilityUser = UserCredentials.compatibility

    override func setUp() {
        continueAfterFailure = false
        
        app = XCUIApplicationBuilder()
            .setupRegion()
            .build()
            .launched()
    }


//    }
//
//    func test_move_msg_to_trash() {
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
//        XCTAssert(app.tables.cells.otherElements.staticTexts[googleUser.email].exists, "There is no message in trash")
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
//    func test_move_msg_to_archive() {
//        wait(2)
//        sendMessage(to: googleUser.email)
//        app.tables.cells.otherElements.staticTexts[googleUser.email].firstMatch.tap()
//        app.navigationBars.buttons["archive"].tap()
//        wait(2)
//        XCTAssert(app.navigationBars["Inbox"].exists, "Failed in sending message to archive")
//
//        menuButton.tap()
//        tapOnMenu(folder: "All Mail")
//        wait(1)
//
//        XCTAssert(app.tables.staticTexts[googleUser.email].exists, "Wrong recipient in sent message")
//        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
//    }
//
//    func test_send_message_no_pub_key() {
//        wait(2)
//        sendMessage(to: "flowcrypt.nopubkey@gmail.com")
//        wait(3)
//        let errorAlert = app.alerts["Error"]
//        XCTAssert(errorAlert.exists)
//    }
}

// MARK: - Compatibility account
extension SignInTest {
    /// log in -> cancel
    func test_1_login_cancel() {
        login()

        let useAnotherAccountButton = app.tables.buttons["Use Another Account"]
        useAnotherAccountButton.tap()

        wait(1)
        XCTAssert(app.tables.buttons["Other email provider"].exists)
    }

    /// log in -> approve -> bad pass phrase
    func test_2_login_bad_pass() {
        login()

        passPhraseTextField.tap()
        passPhraseTextField.typeText(compatibilityUser.pass + "wrong")
        tapOnGoButton()

        wait(0.2)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists, "Error alert is missing after entering wrong pass phrase")
        errorAlert.scrollViews.otherElements.buttons["OK"].tap()
        wait(0.2)

        app.tables.buttons["Use Another Account"].tap()
    }

    /// log in -> approve -> loaded 1 backup -> good pass phrase -> inbox
    func test_3_login_good_pass() {
        login()

        passPhraseTextField.tap()
        passPhraseTextField.typeText(compatibilityUser.pass)

        tapOnGoButton()

        wait(1)
        XCTAssert(app.navigationBars["Inbox"].exists, "Could not login")
    }

    // restart app -> loads inbox
    func test_4_restart_app_load_inbox() {
        wait(1)
        XCTAssert(app.navigationBars["Inbox"].exists, "Inbox is not found after restarting the app")
    }

    // send new msg -> inbox -> switch to sent -> open sent msg and verify content, recipient, subject
    func test_5_send_message() {
        // send message
        sendMessage(to: compatibilityUser.email)
        XCTAssert(app.navigationBars["Inbox"].exists, "Failed state after Sending message")

        // switch to sent
        menuButton.tap()
        app.tables
            .staticTexts
            .allElementsBoundByIndex
            .first(where: { $0.label.contains("Sent" )})?
            .tap()

        wait(3)

        // open message
        tapOnCell()
        wait(5)

        XCTAssert(app.tables.staticTexts[compatibilityUser.email].exists, "Wrong recipient in sent message")
        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
        XCTAssert(app.tables.staticTexts["Some text"].exists, "Wrong text")
    }
}

extension SignInTest {
    private func login() {
        // other account
        let otherEmailButton = app.tables.buttons["Other email provider"]
        otherEmailButton.tap()

        // email
        let emailTextField = app.tables.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText(compatibilityUser.email)

        // password
        let passwordTextField = app.tables.secureTextFields["Password"]
        passwordTextField.tap()
        passwordTextField.typeText(compatibilityUser.password)

        // connect
        passwordTextField.swipeUp()
        app.tables.buttons["Connect"].tap()
        wait(7)
    }
}

// MARK: - Helpers
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

    private var passPhraseTextField: XCUIElement {
        app.tables.secureTextFields["Enter your pass phrase"]
    }
}

// MARK: - Actions
extension SignInTest {
    private func sendMessage(to recipient: String ) {
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

    private func tapOnGoButton() {
        let button = goKeyboardButton
        if button.exists {
            button.tap()
        } else {
            _ = app.keys["\n"]
        }
    }
}

/*
 log in -> approve -> no backups -> switch email
 log in -> approve -> no backups -> generate pubkey -> weak pass phrase
 log in -> approve -> no backups -> generate pubkey -> good pass phrase -> wrong repeat
 log in -> approve -> no backups -> generate pubkey -> good pass phrase -> correct repeat -> create key
 log in -> approve -> no backups -> generate pubkey -> switch accounts



 send new msg -> no pubkey
 move msg to archive -> verify in archive
 move msg to Trash -> verify in trash -> verify no bin button on moved msg
 inbox -> open first msg -> to trash -> inbox -> open following first msg (to prevent crash as in #119)
 */
