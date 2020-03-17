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
    let user = UserCredentials.default

    override func setUp() {
        continueAfterFailure = true
        
        app = XCUIApplicationBuilder()
            .setupRegion()
            .build()
            .launched()
    }

    func test_cancel_login() {
        app.tables/*@START_MENU_TOKEN@*/.buttons["gmail"]/*[[".cells.buttons[\"gmail\"]",".buttons[\"gmail\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
            .tap()
        wait(1)

        let cancelButton = gmailAlert().buttons["Cancel"]
        XCTAssert(cancelButton.exists, "Cancel in Alert doesn't exist")
        cancelButton.tap()

        wait(1)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists) 
    }

    func test_gmail_login() {
        // tap on gmail button
        // MARK: - Google Login
        app.tables/*@START_MENU_TOKEN@*/.buttons["gmail"]/*[[".cells.buttons[\"gmail\"]",".buttons[\"gmail\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let signInAlert = gmailAlert()

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
        let returnButton = goKeyboardButton()
        XCTAssert(returnButton.exists, "User keyboard button")
        returnButton.tap()

        wait(1)

        // enter password
        let passwordTextField = webView.secureTextFields.firstMatch
        passwordTextField.tap()
        passwordTextField.typeText(user.password)
        let goButton = goKeyboardButton()
        XCTAssert(goButton.exists, "Password keyboard button")
        goButton.tap()

        wait(5)

        XCTAssert(app.tables.firstMatch.exists, "Table does not exist")


        // MARK: - Wrong pass phrase
        // enter wrong pass phrase and tap enter
        let button = goKeyboardButton()

        app.typeText(user.pass + "wrong")
        button.tap()

        wait(0.2)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists, "Error alert is missing after entering wrong pass phrase")
        errorAlert.scrollViews.otherElements.buttons["OK"].tap()
        wait(0.2)
        app.tables.secureTextFields.firstMatch.tap()


        // MARK: - Coorect pass phrase
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
        sendMessage()
        XCTAssert(app.navigationBars["Inbox"].exists, "Failed state after Sending message")

        // MARK: - Check in sent mail box
        menuButton().tap()
        wait(0.3)
        app.tables.staticTexts["Sent Mail"].tap()
        wait(5)

        app.tables.cells.otherElements.staticTexts[user.email].firstMatch.tap()
        wait(7)

        XCTAssert(app.tables.staticTexts[user.email].exists, "Wrong recipient in sent message")
        XCTAssert(app.tables.staticTexts["Some Subject"].exists, "Wrong subject")
        XCTAssert(app.tables.staticTexts["Some text"].exists, "Wrong text")


        // MARK: - Delete
        app.navigationBars.buttons["Delete"].tap()
        wait(5)
        menuButton().tap()
        app.tables.staticTexts["Trash"].tap()
        wait(2)
        XCTAssert(app.tables.cells.otherElements.staticTexts[user.email].exists, "There is no message in trash")

 //        let cellsQuery = tablesQuery.cells
//        cellsQuery.otherElements.containing(.staticText, identifier:"5:44 PM").staticTexts["cryptup.tester@gmail.com"].tap()
//
//        let trashNavigationBar = app.navigationBars["Trash"]
//        trashNavigationBar.buttons["help icn"].tap()
//        trashNavigationBar.buttons["arrow left c"].tap()
//        trashNavigationBar.buttons["menu icn"].tap()
//        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Starred"]/*[[".cells.staticTexts[\"Starred\"]",".staticTexts[\"Starred\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Encrypted message sent"]/*[[".cells.staticTexts[\"Encrypted message sent\"]",".staticTexts[\"Encrypted message sent\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//
//        let starredNavigationBar = app.navigationBars["Starred"]
//        starredNavigationBar.buttons["arrow left c"].tap()
//        starredNavigationBar.buttons["menu icn"].tap()
//        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Inbox"]/*[[".cells.staticTexts[\"Inbox\"]",".staticTexts[\"Inbox\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        cellsQuery.otherElements.containing(.staticText, identifier:"16 Mar").staticTexts["Google"].tap()
//        inboxNavigationBar.buttons["archive"].tap()


        // MARK: - Archive
        menuButton().tap()
        app.tables.staticTexts["Inbox"].tap()
        wait(2)
        sendMessage()
        app.tables.cells.otherElements.staticTexts[user.email].firstMatch.tap()
        app.navigationBars.buttons["archive"].tap()
        wait(3)
        XCTAssert(app.navigationBars["Inbox"].exists, "Failed in sending message to archive")
    }

    func test_navigation_bar_in_trash_folder() {
        menuButton().tap()
        wait(0.5)
        app.tables.staticTexts["Trash"].tap()
        wait(1)
        app.tables.cells.allElementsBoundByIndex.filter { $0.frame.origin.x >= 0 }.first?.tap()
        wait(1)

        let buttons = app.navigationBars.buttons


        XCTAssert(buttons["Delete"].exists, "Navigation bar should contain delete button")
        XCTAssert(buttons["help icn"].exists, "Navigation bar should contain help button")
        XCTAssert(buttons["arrow left c"].exists, "Navigation bar should contain back button")
        XCTAssert(buttons.count == 3, "")
    }

    // MARK: - Send message
    private func sendMessage() {
        app.buttons["+"].tap()
        wait(0.2)
        app.typeText(user.email)
        app.tables.textFields["Subject"].tap()

        app.tables.textFields["Subject"].tap()
        app.typeText("Some Subject")
        let nextCompose = goKeyboardButton()
        nextCompose.tap()
        app.typeText("Some text")
        app.navigationBars["Inbox"].buttons["android send"].tap()
        wait(5)
    }
}

extension SignInTest {

    private func goKeyboardButton() -> XCUIElement {
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

    private func gmailAlert() -> XCUIElement {
        Springboard.springboard.alerts.element
    }

    private func menuButton() -> XCUIElement {
        app.navigationBars.buttons["menu icn"]
    }
}
