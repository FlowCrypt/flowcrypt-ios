//
//  SignInViewControllerTest.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest

// MARK: - Compatibility account

class SignInTest: XCTestCase, AppTest {
    var app: XCUIApplication!
    private let user = UserCredentials.compatibility

    override func setUp() {
        continueAfterFailure = false
        
        app = XCUIApplicationBuilder()
            .setupRegion()
            .build()
            .launched()
    } 
}

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
        passPhraseTextField.typeText(user.pass + "wrong")
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
        passPhraseTextField.typeText(user.pass)

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
        sendMessage(to: user.email)
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

        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
        XCTAssert(app.tables.staticTexts["Some text"].exists, "Wrong text")
    }


    // move msg to trash -> verify in trash
    func test_6_delete_msg() {
        // Move msg to Trash
        sendMessage(to: user.email)
        tapOnCell()

        app.navigationBars.buttons["Delete"].tap()
        wait(1)

        // Verify in Trash
        menuButton.tap()
        tapOnMenu(folder: "Deleted")
        XCTAssert(app.tables.cells.otherElements.staticTexts[user.email].exists, "There is no message in deleted")

        tapOnCell()
        let buttons = app.navigationBars.buttons
        let backButton = buttons["arrow left c"]

        // Verify buttons in Trash folder
        XCTAssert(buttons["Delete"].exists, "Navigation bar should contain delete button")
        XCTAssert(buttons["help icn"].exists, "Navigation bar should contain help button")
        XCTAssert(backButton.exists, "Navigation bar should contain back button")

        // TODO: ANTON - remove unread in trash(deleted)
        XCTAssert(buttons.count == 4, "back, info, delete, unread buttons should be only")

        // Open following first msg
        backButton.tap()
        menuButton.tap()
        tapOnMenu(folder: "Inbox")

        tapOnCell()
    }

    // move msg to archive -> verify in archive
    func test_7_archive() {
        sendMessage(to: user.email)
        tapOnCell()
        app.navigationBars.buttons["archive"].tap()
        wait(2)
        XCTAssert(app.navigationBars["Inbox"].exists, "Failed in sending message to archive")

        menuButton.tap()
        // TODO: ANTON - Archive
//        tapOnMenu(folder: "All Mail")
//        wait(1)
//
//        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
//        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
    }

    // send new msg -> no pubkey
    func test_8_send_message_no_pub_key() {
        wait(2)
        sendMessage(to: "flowcrypt.nopubkey@gmail.com")
        wait(3)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists)
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
        emailTextField.typeText(user.email)

        // password
        let passwordTextField = app.tables.secureTextFields["Password"]
        passwordTextField.tap()
        passwordTextField.typeText(user.password)

        // connect
        passwordTextField.swipeUp()
        app.tables.buttons["Connect"].tap()
        wait(7)
    }
}

/*
 log in -> approve -> no backups -> switch email
 log in -> approve -> no backups -> generate pubkey -> weak pass phrase
 log in -> approve -> no backups -> generate pubkey -> good pass phrase -> wrong repeat
 log in -> approve -> no backups -> generate pubkey -> good pass phrase -> correct repeat -> create key
 log in -> approve -> no backups -> generate pubkey -> switch accounts
 */
