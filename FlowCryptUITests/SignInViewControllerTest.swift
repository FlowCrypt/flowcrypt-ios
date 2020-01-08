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
        Springboard.deleteApp()
        continueAfterFailure = false
        app = XCUIApplicationBuilder()
            .reset()
            .setupRegion()
            .build()
        app.launch()
    }

    override class func tearDown() {
        super.tearDown()
    }

    func test_existence_of_elements() {
        let elementsQuery = app.tables
        XCTAssertTrue(wait(for: elementsQuery.buttons["privacy"], timeout: 2))
        XCTAssertTrue(wait(for: elementsQuery.buttons["terms"], timeout: 2))
        XCTAssertTrue(wait(for: elementsQuery.buttons["security"], timeout: 2))
        XCTAssertTrue(wait(for: elementsQuery.buttons["gmail"], timeout: 2))
        XCTAssertTrue(wait(for: elementsQuery.buttons["outlook"], timeout: 2))
        XCTAssertTrue(wait(for: elementsQuery.staticTexts["description"], timeout: 2))
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
        textField.typeText("cryptup.tester@gmail.com")
    }
}
