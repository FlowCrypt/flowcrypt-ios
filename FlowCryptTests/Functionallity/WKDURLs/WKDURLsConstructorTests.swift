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

    func test_direct_mode_lowercased_construct_URL_success() {
        let inputEmail = "recipient.hello@example.com"
        let expectedURL = "https://example.com/.well-known/openpgpkey/hu/1sbjrcaf8m3zckmmuej93nx61yn1sttg?l=recipient.hello"
        
        let constructedURL = constructor.construct(from: inputEmail, mode: .direct)
        
        XCTAssert(constructedURL == expectedURL)
    }
    
    func test_advanced_mode_lowercased_construct_URL_success() {
        let inputEmail = "recipient.hello@example.com"
        let expectedURL = "https://openpgpkey.example.com/.well-known/openpgpkey/example.com/hu/1sbjrcaf8m3zckmmuej93nx61yn1sttg?l=recipient.hello"
        
        let constructedURL = constructor.construct(from: inputEmail, mode: .advanced)
        
        XCTAssert(constructedURL == expectedURL)
    }
    
    func test_direct_mode_uppercased_construct_URL_success() {
        let inputEmail = "UPPER@EXAMPLE.COM"
        let expectedURL = "https://example.com/.well-known/openpgpkey/hu/awhcnhf7a4ax8qha5u1rwymkfaswmjz8?l=UPPER"
        
        let constructedURL = constructor.construct(from: inputEmail, mode: .direct)
        
        XCTAssert(constructedURL == expectedURL)
    }
    
    func test_advanced_mode_uppercased_construct_URL_success() {
        let inputEmail = "UPPER@EXAMPLE.COM"
        let expectedURL = "https://openpgpkey.example.com/.well-known/openpgpkey/example.com/hu/awhcnhf7a4ax8qha5u1rwymkfaswmjz8?l=UPPER"
        
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
