//
//  SignInViewControllerTest.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest
import FlowCryptCommon

/// make ui_tests_imap
class SignInImapTest: XCTestCase, AppTest {
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        
        logger.logInfo("Start App")
        
        app = XCUIApplicationBuilder()
            .setupRegion()
            .build()
            .addSnapshot()
            .launched()
        
        logger.logInfo("Wait for launch")
        wait(10)
    }
    
    // login -> approve -> backups found -> enter pass phrase -> main flow
    func test_1_successful_login_imap() {
        let user = UserCredentials.imapDev
        loginWithImap(user)
        
        passPhraseTextField.tap()
        passPhraseTextField.typeText(user.pass)
        goKeyboardButton.tap()
        
        wait(4)
        XCTAssert(app.buttons["+"].exists)
    }
    
    // restart app -> loads inbox
    func test_2_restart_app_load_inbox() {
        let application = XCUIApplication()
        wait(2)
        application.buttons["+"].tap()
        
        wait(0.3)
        
        application.typeText("test@test.com")
        application.tables.textFields["Subject"].tap()
        wait(3)
        application.tables.textFields["Subject"].tap()
        
        application.typeText("ios")
        
        snapshot("compose")
        navigationBackButton.tap()
        wait(1)
        
        tapOnCell()
        snapshot("message")
        navigationBackButton.tap()
        
        wait(1)
        
        menuButton.tap()
        snapshot("menu")
        
        tapOnMenu(folder: "Settings")
        snapshot("settings")
        
        // TODO: - https://github.com/FlowCrypt/flowcrypt-ios/issues/470
        /*
         let app = XCUIApplication()
         let inboxNavigationBar = app.navigationBars["Inbox"]
         inboxNavigationBar.buttons["help icn"].tap()
         inboxNavigationBar.buttons["search icn"].tap()
         app.otherElements["PopoverDismissRegion"].tap()
         app.navigationBars["Search"].buttons["arrow left c"].tap()
         
         let tablesQuery2 = app.tables
         let cellsQuery = tablesQuery2.cells
         cellsQuery.otherElements.containing(.staticText, identifier:"Jun 07").staticTexts["denbond7@flowcrypt.test"].tap()
         tablesQuery2.children(matching: .cell).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element.children(matching: .textView).element.children(matching: .textView)["It's an encrypted text"].tap()
         inboxNavigationBar.buttons["arrow left c"].tap()
         
         let tablesQuery = tablesQuery2
         tablesQuery.staticTexts["..."].tap()
         
         //
         cellsQuery.otherElements.containing(.staticText, identifier:"encrypted message with missing key error").staticTexts["denbond7@flowcrypt.test"].tap()
         tablesQuery.textViews.textViews["Could not decrypt:"].tap()*/
    }
    
    // login -> cancel
    func test_3_login_cancel() {
        let user = UserCredentials.imapDev
        loginWithImap(user)

        passPhraseTextField.swipeUp()
        tapUseAnotherAccountAndVerify()
    }
    
    // login with user without key backups and emails
    // login -> no messages
    func test_4_login_no_messages() {
        verifyFlowWithNoBackups(for: .imapDen)
    }

    func test_5_has_msgs_no_backups() {
        verifyFlowWithNoBackups(for: .imapHasMessagesNoBackups)
    }
    
    // login with wrong pass phrase
    func test_6_login_bad_pass_phrase() {
        let user = UserCredentials.imapDev
        loginWithImap(user)
        
        let tablesQuery = app.tables
        XCTAssert(tablesQuery.staticTexts["Remember pass phrase temporarily"].exists)
        
        passPhraseTextField.typeText(user.pass + "wrong")
        tapOnGoButton()
        wait(2)
        
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists, "Error alert is missing after entering wrong pass phrase")
        XCTAssert(errorAlert.scrollViews.otherElements.staticTexts["Wrong pass phrase, please try again"].exists)
        errorAlert.scrollViews.otherElements.buttons["OK"].tap()
        wait(0.2)
        app.tables.buttons["Use Another Account"].tap()
    }
}

// MARK: - Convenience
extension SignInImapTest {
    private var toolbarDoneButton: XCUIElement {
        app.toolbars["Toolbar"].buttons["Done"]
    }
    
    private func loginWithImap(_ user: UserCredentials) {
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
        wait(1)
        
        // move focus to username
        goKeyboardButton.tap()
        wait(1)
        
        // move focus to password
        goKeyboardButton.tap()
        app.typeText(user.password)
        
        // move focus to imap server (filled)
        goKeyboardButton.tap()
        
        // move focus to imap port
        goKeyboardButton.tap()
        
        // move focus to imap security type. Set none
        toolbarDoneButton.tap()
        app.pickerWheels["none"].tap()
        toolbarDoneButton.tap()
        
        // move to smtp type
        let smtpType = app.tables.textFields["SMTP type"]
        smtpType.tap()
        app.pickerWheels["none"].tap()
        toolbarDoneButton.tap()
        
        app.tables.buttons["Connect"].tap()
        
        logger.logInfo("Try to connect")
        wait(10)
    }
    
    private func verifyFlowWithNoBackups(for user: UserCredentials) {
        loginWithImap(user)
        
        let tablesQuery = app.tables
        
        let noBackupsLabel = tablesQuery.staticTexts["No backups found on account: \n\(user.email)"]
        let importMyKeyButton = tablesQuery.buttons["Import my key"]
        let createNewKeyButton = tablesQuery.buttons["Create a new key"]
        
        XCTAssert(noBackupsLabel.exists)
        XCTAssert(importMyKeyButton.exists)
        XCTAssert(createNewKeyButton.exists)
        XCTAssert(setupUseAnotherAccount.exists)
        
        importMyKeyButton.tap()
        navigationBackButton.tap()
        
        createNewKeyButton.tap()
        navigationBackButton.tap()
        
        importMyKeyButton.tap()
        
        let loadFromFileButton = tablesQuery.buttons["Load From File"]
        XCTAssert(loadFromFileButton.exists)
        
        let loadFromClipboard = tablesQuery.buttons["Load From Clipboard"]
        XCTAssert(loadFromClipboard.exists)
        navigationBackButton.tap()
        
        XCTAssert(noBackupsLabel.exists)
        
        tapUseAnotherAccountAndVerify()
    }
    
    private func tapUseAnotherAccountAndVerify() {
        setupUseAnotherAccount.tap()
        
        wait(1)
        XCTAssert(app.tables.buttons["Other email provider"].exists)
    }
}

// Currently disabled tests
// UI tests which can make changes on remote server are currently disabled

//    func test_2_login_no_backups_generate() {
//        // log in -> approve -> no backups -> generate pubkey -> weak pass phrase
//        login(UserCredentials.noKeyBackUp)
//        wait(1)
//
//        let alertButtons = app.alerts.scrollViews.otherElements.buttons
//        alertButtons["Create new Private Key"].tap()
//
//        passPhraseTextField.tap()
//        passPhraseTextField.typeText("Password")
//        goKeyboardButton.tap()
//        wait(2)
//
//        XCTAssert(app.alerts["Error"].exists, "Error alert for weak pass phrase should exist")
//
//        app.alerts["Error"].scrollViews.otherElements.buttons["OK"].tap()
//        wait(0.1)
//
//        // log in -> approve -> no backups -> generate pubkey -> good pass phrase -> wrong repeat
//        passPhraseTextField.tap()
//        passPhraseTextField.typeText(user.pass)
//        goKeyboardButton.tap()
//        wait(2)
//
//        app.alerts["Pass Phrase"].scrollViews.otherElements.buttons["OK"].tap()
//        XCTAssert(app.alerts["Error"].exists, "Error alert for wrong repeat pass phrase should exist")
//
//        app.alerts["Error"].scrollViews.otherElements.buttons["OK"].tap()
//
//        // log in -> approve -> no backups -> generate pubkey -> good pass phrase -> correct repeat -> create key
//        passPhraseTextField.tap()
//        let pass = user.pass.replacingOccurrences(of: " ", with: "")
//        passPhraseTextField.typeText(pass)
//        goKeyboardButton.tap()
//        wait(2)
//
//        // TODO: ANTON - fix this
//        let secureTextField = app.alerts["Pass Phrase"].scrollViews.otherElements.collectionViews.cells.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .secureTextField).element
//        secureTextField.typeText(pass)
//        app.alerts["Pass Phrase"].scrollViews.otherElements.buttons["OK"].tap()
//        wait(10)
//        // Temporary confirm on error alert.
//        if app.alerts["Error"].exists {
//            app.alerts["Error"].scrollViews.otherElements.buttons["OK"].tap()
//            wait(2)
//        }
//
//        // delete backups to trash
//        cells.forEach { _ in
//            tapOnCell()
//            app.navigationBars["Inbox"].buttons["Delete"].tap()
//            wait(2)
//        }
//
//        // permanently delete backups
//        menuButton.tap()
//        tapOnMenu(folder: "Deleted")
//
//        cells.forEach { _ in
//            tapOnCell()
//            self.app.navigationBars["Deleted"].buttons["Delete"].tap()
//            self.app.alerts["Are you sure?"].scrollViews.otherElements.buttons["OK"].tap()
//            wait(2)
//        }
//    }
//
 

//
//    // send new msg -> inbox -> switch to sent -> open sent msg and verify content, recipient, subject
//    func test_8_send_message() {
//        // send message
//        sendMessage(to: user.email)
//        XCTAssert(app.navigationBars["Inbox"].exists, "Failed state after Sending message")
//
//        // switch to sent
//        menuButton.tap()
//
//        app.tables
//            .staticTexts
//            .allElementsBoundByIndex
//            .first(where: { $0.label.contains("Sent" ) })?
//            .tap()
//
//        wait(3)
//
//        // open message
//        tapOnCell()
//        wait(5)
//
//        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
//        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
//        XCTAssert(app.tables.staticTexts["Some text"].exists, "Wrong text")
//    }
//
//    // move msg to trash -> verify in trash
//    func test_9_delete_msg() {
//        // Move msg to Trash
//        sendMessage(to: user.email)
//        tapOnCell()
//
//        app.navigationBars.buttons["Delete"].tap()
//        wait(1)
//
//        // Verify in Trash
//        menuButton.tap()
//        tapOnMenu(folder: "Deleted")
//        XCTAssert(app.tables.cells.otherElements.staticTexts[user.email].exists, "There is no message in deleted")
//
//        tapOnCell()
//        let buttons = app.navigationBars.buttons
//        let backButton = buttons["arrow left c"]
//
//        wait(3)
//        // Verify buttons in Trash folder
//        XCTAssert(buttons["Delete"].exists, "Navigation bar should contain delete button")
//        XCTAssert(buttons["help icn"].exists, "Navigation bar should contain help button")
//        XCTAssert(backButton.exists, "Navigation bar should contain back button")
//        XCTAssert(buttons.count == 3, "back, info, delete buttons should be only")
//
//        // Open following first msg
//        backButton.tap()
//        menuButton.tap()
//        tapOnMenu(folder: "Inbox")
//
//        tapOnCell()
//    }
//
//    // move msg to archive -> verify in archive
//    func test_10_archive() {
//        sendMessage(to: user.email)
//        tapOnCell()
//        app.navigationBars.buttons["archive"].tap()
//        wait(2)
//        XCTAssert(app.navigationBars["Inbox"].exists, "Failed in sending message to archive")
//
//        menuButton.tap()
//        // TODO: ANTON - Archive
////        tapOnMenu(folder: "All Mail")
////        wait(1)
////
////        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
////        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
//    }
//
//    // send new msg -> no pubkey
//    func test_11_send_message_no_pub_key() {
//        wait(2)
//        sendMessage(to: "flowcrypt.nopubkey@gmail.com")
//        wait(3)
//        let errorAlert = app.alerts["Error"]
//        XCTAssert(errorAlert.exists)
//    }
//}
