//
//  SignInViewControllerTest.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import XCTest

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
    func test_2_restart_load_inbox() {
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
    }

    // restart app -> loads inbox -> verify messages
    func test_3_restart_contains_emails() {
        let app = XCUIApplication()

        let tablesQuery = app.tables
        let cellsQuery = tablesQuery.cells

        // open first message
        cellsQuery.otherElements.containing(.staticText, identifier:"Jun 07").staticTexts["denbond7@flowcrypt.test"].tap()
        navigationBackButton.tap()

        // message > 5mb
        cellsQuery.otherElements.containing(.staticText, identifier:"...").staticTexts["denbond7@flowcrypt.test"].tap()
        wait(0.5)

        cellsQuery.otherElements.containing(.staticText, identifier:"encrypted message with missing key error").staticTexts["denbond7@flowcrypt.test"].tap()
        tablesQuery.textViews.textViews["Could not decrypt:"].tap()
        navigationBackButton.tap()

        // open 3d message
        cellsQuery.otherElements.containing(.staticText, identifier:"Simple encrypted message").staticTexts["denbond7@flowcrypt.test"].tap()
        let textView = tablesQuery.children(matching: .cell)
            .element(boundBy: 2)
            .children(matching: .other)
            .element
            .children(matching: .other)
            .element
            .children(matching: .textView)
            .element
        textView.children(matching: .textView)["Simple encrypted text"].tap()
        navigationBackButton.tap()

        // open 4th message
        cellsQuery.otherElements.containing(.staticText, identifier:"Simple encrypted message + pub key").staticTexts["denbond7@flowcrypt.test"].tap()
        textView.children(matching: .textView)["It's an encrypted message with my pub key"].tap()
        navigationBackButton.tap()

        // open message with attachment
        cellsQuery.otherElements.containing(.staticText, identifier:"Simple encrypted message + attachment").staticTexts["denbond7@flowcrypt.test"].tap()
        tablesQuery.staticTexts["android.png.pgp"].tap()
        wait(1)
        cellsQuery.otherElements.containing(.staticText, identifier:"denbond7@flowcrypt.test").children(matching: .button).element.tap()
        navigationBackButton.tap()

        tablesQuery.staticTexts["Simple encrypted message + attachment"].tap()
        textView.children(matching: .textView)["It's an encrypted message with one encrypted attachment."].tap()
    }

    // restart app -> search functionality
    func test_4_restart_search() {
        // search
        let inboxNavigationBar = app.navigationBars["Inbox"]
        let searchButton = inboxNavigationBar.buttons["search icn"]
        let tablesQuery = app.tables

        searchButton.tap()

        let searchNavigationBar = app.navigationBars["Search"]
        let searchTextField = searchNavigationBar.searchFields["Search"]

        searchTextField.tap()
        wait(1)
        searchTextField.typeText("search")

        // Verify result with "search"
        let denBondMessage = tablesQuery.staticTexts["denbond7@flowcrypt.test"]
        denBondMessage.tap()
        // Search in subject
        tablesQuery.staticTexts["Search"].tap()
        let textView = tablesQuery.children(matching: .cell).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element.children(matching: .textView).element
        // body
        textView.children(matching: .textView)["Search in the body"].tap()
        // email in recipient
        denBondMessage.tap()
        // go back to search controller
        navigationBackButton.tap()
        searchTextField.tap()

        // clear previous result
        let clearTextButton = searchTextField.buttons["Clear text"]
        clearTextButton.tap()

        // ESPRESSO
        searchTextField.tap()
        searchTextField.typeText("espresso")

        let espresso = tablesQuery.staticTexts["'espresso' in a subject"]
        espresso.tap()
        espresso.tap()
        textView.children(matching: .textView)["Some text"].tap()
        navigationBackButton.tap()

        let cellsQuery = tablesQuery.cells
        cellsQuery.otherElements.containing(.staticText, identifier:"Message").staticTexts["denbond7@flowcrypt.test"].tap()
        tablesQuery.staticTexts["Message"].tap()
        textView.children(matching: .textView)["The message with 'espresso' in a body"].tap()
        navigationBackButton.tap()
        clearTextButton.tap()

        // ANDROID
        searchTextField.tap()
        searchTextField.typeText("android")
        cellsQuery.otherElements.containing(.staticText, identifier:"Standard message + one attachment").staticTexts["denbond7@flowcrypt.test"].tap()
        navigationBackButton.tap()
        cellsQuery.otherElements.containing(.staticText, identifier:"With android in subject").staticTexts["denbond7@flowcrypt.test"].tap()
        navigationBackButton.tap()
        cellsQuery.otherElements.containing(.staticText, identifier:"with that text in body").staticTexts["denbond7@flowcrypt.test"].tap()
        navigationBackButton.tap()
        cellsQuery.otherElements.containing(.staticText, identifier:"Honor reply-to address").staticTexts["denbond7@flowcrypt.test"].tap()
        navigationBackButton.tap()
        cellsQuery.otherElements.containing(.staticText, identifier:"Simple encrypted message + attachment").staticTexts["denbond7@flowcrypt.test"].tap()
        navigationBackButton.tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .table).element.tap()
        navigationBackButton.tap()
    }

    // restart app -> verify folders
    func test_5_restart_folders() {
        let app = XCUIApplication()
        let tablesQuery = app.tables

        let menuButton = app.navigationBars["Inbox"].buttons["menu icn"]
        menuButton.tap()
        wait(1)
        tablesQuery.cells.otherElements.containing(.staticText, identifier:"...").staticTexts["denbond7@flowcrypt.test"].tap()
        menuButton.tap()

        tablesQuery.staticTexts["Junk"].tap()
        tablesQuery.staticTexts["Junk is empty"].tap()
        app.navigationBars["Junk"].buttons["menu icn"].tap()

        tablesQuery.staticTexts["Drafts"].tap()
        tablesQuery.staticTexts["Drafts is empty"].tap()
        app.navigationBars["Drafts"].buttons["menu icn"].tap()

        tablesQuery.staticTexts["Trash"].tap()
        tablesQuery.staticTexts["Standard message - plaintext"].tap()
        navigationBackButton.tap()
        app.navigationBars["Trash"].buttons["menu icn"].tap()

        tablesQuery.staticTexts["Sent"].tap()
        tablesQuery.staticTexts["Sent is empty"].tap()
        app.navigationBars["Sent"].buttons["menu icn"].tap()

        tablesQuery.staticTexts["Inbox"].tap()
        menuButton.tap()
    }

    // restart app -> verify settings
    func test_6_restart_settings() {
        let app = XCUIApplication()
        let tablesQuery = app.tables

        menuButton.tap()
        wait(1)

        tablesQuery.staticTexts["Settings"].tap()
        tablesQuery.staticTexts["Backups"].tap()
        navigationBackButton.tap()
        tablesQuery.staticTexts["Security and Privacy"].tap()
        tablesQuery.staticTexts["Contacts"].tap()

        app.navigationBars["Contacts"].staticTexts["Contacts"].tap()
        navigationBackButton.tap()

        tablesQuery.staticTexts["Keys"].tap()
        wait(1)
        tablesQuery.cells.firstMatch.tap()
        tablesQuery.buttons["Show public key"].tap()

        // part of public key
        let searchText = "nxjMEYIq7phYJKwYBBAHaRw8BAQdAat45rrh"
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", searchText)
        tablesQuery.containing(predicate)

        navigationBackButton.tap()

        tablesQuery.buttons["Show key details"].tap()
        tablesQuery.staticTexts["Longid: 225F8023C20D0957"].tap()
        tablesQuery.staticTexts["Longid: 4F1458BD22B7BB53"].tap()

        navigationBackButton.tap()
        tablesQuery.buttons["Copy to clipboard"].tap()
        tablesQuery.buttons["Share"].tap()
        app.navigationBars["UIActivityContentView"].buttons["Close"].tap()
        tablesQuery.buttons["Show private key"].tap()

        navigationBackButton.tap()

        app.navigationBars["Keys"].buttons["Add"].tap()
        XCTAssert(tablesQuery.buttons["Load From File"].exists)
        navigationBackButton.tap()
        navigationBackButton.tap()

        tablesQuery.staticTexts["Notifications"].tap()
        tablesQuery.staticTexts["Legal"].tap()

        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.staticTexts["Terms"].tap()
        collectionViewsQuery.staticTexts["License"].tap()
        collectionViewsQuery.staticTexts["Sources"].tap()
        app.navigationBars["Legal"].buttons["arrow left c"].tap()
        tablesQuery.staticTexts["Experimental"].tap()
    }

    // restart app -> Try to send message to user without pub key
    func test_7_restart_send_message_no_pub_key() {
        let application = XCUIApplication()
        application.buttons["+"].tap()

        wait(0.3)

        application.typeText("test@test.com")
        app.navigationBars["Inbox"].buttons["android send"].tap()

        let errorAlert = app.alerts["Error"].scrollViews.otherElements
        XCTAssert(errorAlert.staticTexts["Could not compose message\n\nEnter subject"].exists)
        errorAlert.buttons["OK"].tap()

        application.tables.textFields["Subject"].tap()
        wait(1)
        application.tables.textFields["Subject"].tap()
        app.typeText("Subject")
        app.navigationBars["Inbox"].buttons["android send"].tap()

        let errorMessage = application.alerts["Error"].scrollViews.otherElements
        XCTAssert(errorAlert.staticTexts["Could not compose message\n\nEnter secure message"].exists)
        errorMessage.buttons["OK"].tap()

        let cell = app.tables.children(matching: .cell).element(boundBy: 5)
        cell.tap()
        app.typeText("Message")
        app.navigationBars["Inbox"].buttons["android send"].tap()

        XCTAssert(errorAlert.staticTexts["Could not compose message\n\nRecipient doesn't seem to have encryption set up"].exists)
        wait(1)
    }

    // restart app -> verify contacts functionality
    func test_9_restart_app_contacts() {
        let application = XCUIApplication()
        let tablesQuery = application.tables
        app.buttons["+"].tap()

        app.typeText(UserCredentials.imapDev.email)
        goKeyboardButton.tap()
        wait(2)

        tablesQuery.textFields["Add Recipient"].tap()
        wait(1)
        app.typeText(UserCredentials.imapDenBond.email)
        wait(1)
        goKeyboardButton.tap()
        wait(1)

        navigationBackButton.tap()

        application.navigationBars["Inbox"].buttons["menu icn"].tap()
        tablesQuery.staticTexts["Settings"].tap()
        tablesQuery.staticTexts["Contacts"].tap()

        wait(1)

        tablesQuery.otherElements["0"].firstMatch.tap()
        app.tables.staticTexts["denbond7@flowcrypt.test"].tap()
        XCTAssert(app.tables.staticTexts["default@flowcrypt.test"].exists)
        XCTAssert(app.tables.staticTexts["C32089CD6AF8D6CE,\nD7A3DEDB65CB1EFB"].exists)
        XCTAssert(app.tables.staticTexts["eddsa"].exists)
        app.navigationBars["Public Key"].buttons["arrow left c"].tap()

        tablesQuery.otherElements["1"].firstMatch.tap()
        XCTAssert(app.tables.staticTexts["default@flowcrypt.test"].exists)
        XCTAssert(app.tables.staticTexts["225F8023C20D0957,\n4F1458BD22B7BB53"].exists)
        XCTAssert(app.tables.staticTexts["3DEBE9F677D5B9BB38E5A244225F8023C20D0957,\nF81D1B0FDEE37AA32B8F0CD04F1458BD22B7BB53"].exists)
        XCTAssert(app.tables.staticTexts["eddsa"].exists)
        application.navigationBars["Public Key"].buttons["arrow left c"].tap()
    }

    // try to sign in with wrong credentials
    func test_9_sign_in_with_wrong_credentials() {
        var user = UserCredentials.imapDev
        user.password = "123"
        loginWithImap(user)

        let errorAlert = app.alerts["Error"].scrollViews.otherElements

        // part of public key
        let searchText = "Connection Error"
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", searchText)
        errorAlert.staticTexts.containing(predicate)
        errorAlert.buttons["OK"].tap()

        XCTAssert(app.tables.buttons["Connect"].exists)
    }

    // login -> cancel
    func test_10_login_cancel() {
        let user = UserCredentials.imapDev
        loginWithImap(user)

        passPhraseTextField.swipeUp()
        tapUseAnotherAccountAndVerify()
    }

    // login with user without key backups and emails
    func test_11_login_no_messages() {
        verifyFlowWithNoBackups(for: .imapDen)
    }

    func test_12_has_msgs_no_backups() {
        verifyFlowWithNoBackups(for: .imapHasMessagesNoBackups)
    }

    // login with wrong pass phrase
    func test_13_login_bad_pass_phrase() {
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
//        let backButton = navigationBackButton
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
