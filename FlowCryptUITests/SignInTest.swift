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
            .addSnapshot()
            .launched()
    } 
}

extension SignInTest {
    // log in -> approve -> no backups -> switch email
    func test_1_login_approve_no_backups() {
        // login with user without key backup
        login(UserCredentials.noKeyBackUp)
        wait(1)

        // retry
        let buttons = app.alerts.scrollViews.otherElements.buttons
        buttons["Retry"].tap()
        wait(1)

        // switch to a new account
        buttons["Use other account"].tap()
        wait(2)

        // login
        test_3_login_good_pass()
    }

    // log in -> cancel for gmail
    func test_1_login_cancel_gmail() {
        logOutIfNeeded()
        snapshot("splash")

        app.tables.buttons["gmail"].tap()
        wait(1)

        snapshot("auth")
    }

    // log in -> cancel
    func test_1_login_cancel() {
        login(user)

        let useAnotherAccountButton = app.tables.buttons["Use Another Account"]
        useAnotherAccountButton.tap()


        wait(1)
        XCTAssert(app.tables.buttons["Other email provider"].exists)
    }

    // log in -> approve -> bad pass phrase
    func test_2_login_bad_pass() {
        login(user)

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

    // log in -> approve -> loaded 1 backup -> good pass phrase -> inbox
    func test_3_login_good_pass() {
        login(user)

        passPhraseTextField.tap()
        passPhraseTextField.typeText(user.pass)

        snapshot("recover")
        tapOnGoButton()

        wait(1)
        XCTAssert(app.navigationBars["Inbox"].exists, "Could not login")
    }

    // restart app -> loads inbox
    func test_4_restart_app_load_inbox() {
        wait(1)
        XCTAssert(app.navigationBars["Inbox"].exists, "Inbox is not found after restarting the app")
        snapshot("inbox")

        tapOnCompose()
        wait(0.3)

        app.typeText("ElonMusk@gmail.com")
        app.tables.textFields["Subject"].tap()

        app.tables.textFields["Subject"].tap()
        app.typeText("SpaceX")

        snapshot("compose")
        app.navigationBars.buttons["arrow left c"].tap()
        wait(1)

        tapOnCell()
        snapshot("message")
        app.navigationBars.buttons["arrow left c"].tap()

        wait(1)

        menuButton.tap()
        snapshot("menu")

        tapOnMenu(folder: "Settings")
        snapshot("settings")
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

        wait(3)
        // Verify buttons in Trash folder
        XCTAssert(buttons["Delete"].exists, "Navigation bar should contain delete button")
        XCTAssert(buttons["help icn"].exists, "Navigation bar should contain help button")
        XCTAssert(backButton.exists, "Navigation bar should contain back button")
        XCTAssert(buttons.count == 3, "back, info, delete buttons should be only")

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

 

/*
 log in -> approve -> no backups -> switch email
 log in -> approve -> no backups -> generate pubkey -> weak pass phrase
 log in -> approve -> no backups -> generate pubkey -> good pass phrase -> wrong repeat
 log in -> approve -> no backups -> generate pubkey -> good pass phrase -> correct repeat -> create key
 log in -> approve -> no backups -> generate pubkey -> switch accounts
 */
