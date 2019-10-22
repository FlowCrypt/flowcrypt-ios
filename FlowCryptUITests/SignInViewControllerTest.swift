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
        continueAfterFailure = false

        app = XCUIApplicationBuilder().reset().build()
        app.launch()
    }

    func test_existence_of_elements() {
        let elementsQuery = app.scrollViews.otherElements
        XCTAssertTrue(UITestHelper.wait(for: elementsQuery.buttons["privacy"], timeout: 5))
        XCTAssertTrue(UITestHelper.wait(for: elementsQuery.buttons["terms"], timeout: 5))
        XCTAssertTrue(UITestHelper.wait(for: elementsQuery.buttons["security"], timeout: 5))
        XCTAssertTrue(UITestHelper.wait(for: elementsQuery.buttons["gmail"], timeout: 5))
        XCTAssertTrue(UITestHelper.wait(for: elementsQuery.buttons["outlook"], timeout: 5))
        XCTAssertTrue(UITestHelper.wait(for: elementsQuery.staticTexts["description"], timeout: 5))
    }
    
}
