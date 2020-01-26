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

    override func setUp() {
        continueAfterFailure = false
        
        app = XCUIApplicationBuilder()
            .reset()
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

        wait(3)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists)




        
    }

    func test_successful_gmail_login() {
        // tap on gmail button
        app.tables/*@START_MENU_TOKEN@*/.buttons["gmail"]/*[[".cells.buttons[\"gmail\"]",".buttons[\"gmail\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
            .tap()
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
        textField.tap()
        let user = UserCredentials.default
        textField.typeText("cryptup.tester@gmail.com")
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

        // enter wrong pass phrase and tap enter

        _ = app.keys[user.pass+"wooorng"+"\n"]
        wait(0.2)
//        app.keys[user.pass+"wooorng"].tap()
//        wait(0.2)
//        app.buttons["Return"].tap()
//        wait(0.2)
        let errorAlert = app.alerts["Error"]
        XCTAssert(errorAlert.exists, "Error alert is missing after entering wrong pass phrase")
        errorAlert.scrollViews.otherElements.buttons["OK"].tap()
        wait(0.2)

        app.tables.secureTextFields.firstMatch.tap()
        wait(0.2)

        let button = goKeyboardButton()
        if button.exists {
            app.typeText(user.pass)
            button.tap()
        } else {
            _ = app.keys[user.pass + "\n"]
        }
        wait(1)

        XCTAssert(app.navigationBars["Inbox"].exists, "Could not login")

        XCUIDevice.shared.press(.home)
        XCUIApplication(bundleIdentifier: Bundle.main.bundleIdentifier!).launch()

        wait(1)
        XCTAssert(app.navigationBars["Inbox"].exists, "Failed state after login")
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
}
