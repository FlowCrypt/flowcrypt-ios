//
//  SignInViewControllerTest.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest

class SignInViewControllerTest: XCTestCase {
    var app: XCUIApplication!

    override func setUp() { 
        Springboard.resetSafari()
        continueAfterFailure = false
        app = XCUIApplicationBuilder()
            .reset()
            .setupRegion()
            .build()
            .launched()
    }

    func test_successful_gmail_login() {
        let gmailButton = app.tables/*@START_MENU_TOKEN@*/.buttons["gmail"]/*[[".cells.buttons[\"gmail\"]",".buttons[\"gmail\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        gmailButton.tap()

        let springboardApp = Springboard.springboard
        let signInAlert = springboardApp.alerts.element

        signInAlert.buttons["Continue"].tap()

        let webView = app.webViews
        
        
        let textField = webView.textFields.firstMatch 
        textField.tap()
        
        let user = UserCredentials.default
        textField.typeText("cryptup.tester@gmail.com")
        
        
        let returnButton: XCUIElement = {
            if app.buttons["return"].exists {
                return app.buttons["return"]
            }
            return app.buttons["Return"]
        }()
        returnButton.tap()
        
        
        let passwordTextField = webView.secureTextFields.firstMatch
        passwordTextField.tap()
        passwordTextField.typeText(user.password)
        
        let goButton: XCUIElement = {
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
        }()
        goButton.tap()
        
        wait(10)
        
        let passPhraseTextField = app.tables.secureTextFields.firstMatch
        passPhraseTextField.tap()
        passPhraseTextField.typeText(user.pass)
        
        app.tables.buttons["Load Account"].tap()
    }
                
}
