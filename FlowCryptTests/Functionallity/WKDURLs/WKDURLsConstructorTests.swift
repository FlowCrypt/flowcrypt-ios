//
//  WKDURLsTests.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest

class WKDURLsTests: XCTestCase {
    
    var constructor: WKDURLsConstructorType!

    override func setUp() {
        constructor = WKDURLsConstructor()
    }

    override func tearDown() {
        constructor = nil
    }

    func test_direct_mode_construct_URL_success() {
        let inputEmail = "example@mail.com"
        let expectedURL = "https://mail.com/.well-known/openpgpkey/hu/cihgn5mopt1o?l=example"
        
        let constructedURL = constructor.construct(from: inputEmail, mode: .direct)
        
        XCTAssert(constructedURL == expectedURL)
    }
    
    func test_advanced_mode_construct_URL_success() {
        let inputEmail = "example@mail.com"
        let expectedURL = "https://openpgpkey.mail.com.well-known/openpgpkey/mail.com/hu/cihgn5mopt1o?l=example"
        
        let constructedURL = constructor.construct(from: inputEmail, mode: .advanced)
        
        XCTAssert(constructedURL == expectedURL)
    }
    
    func test_construct_URL_failure() {
        var inputEmail = "examplemail.com"
        var constructedURL = constructor.construct(from: inputEmail, mode: .advanced)
        
        XCTAssertNil(constructedURL)
        
        inputEmail = "example@"
        
        constructedURL = constructor.construct(from: inputEmail, mode: .advanced)
        
        XCTAssertNil(constructedURL)
        
        inputEmail = "@mail.com"
        
        constructedURL = constructor.construct(from: inputEmail, mode: .advanced)
        
        XCTAssertNil(constructedURL)
    }
}
