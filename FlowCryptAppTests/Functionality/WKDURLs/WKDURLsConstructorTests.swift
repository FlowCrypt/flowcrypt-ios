//
//  WKDURLsConstructorTests.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class WKDURLsTests: XCTestCase {

    var sut: WkdUrlConstructorType!

    override func setUp() {
        sut = WkdUrlConstructor()
    }

    override func tearDown() {
        sut = nil
    }

    func test_direct_mode_lowercased_construct_URL_success() {
        let url = sut.construct(from: "recipient.hello@example.com", method: .direct)
        XCTAssert(url?.pubKeys == "https://example.com/.well-known/openpgpkey/hu/1sbjrcaf8m3zckmmuej93nx61yn1sttg?l=recipient.hello")
        XCTAssert(url?.policy == "https://example.com/.well-known/openpgpkey/policy")
    }

    func test_advanced_mode_lowercased_construct_URL_success() {
        let url = sut.construct(from: "recipient.hello@example.com", method: .advanced)
        XCTAssert(url?.pubKeys == "https://openpgpkey.example.com/.well-known/openpgpkey/example.com/hu/1sbjrcaf8m3zckmmuej93nx61yn1sttg?l=recipient.hello")
        XCTAssert(url?.policy == "https://openpgpkey.example.com/.well-known/openpgpkey/example.com/policy")
    }

    func test_direct_mode_uppercased_construct_URL_success() {
        let url = sut.construct(from: "UPPER@EXAMPLE.COM", method: .direct)
        XCTAssert(url?.pubKeys == "https://example.com/.well-known/openpgpkey/hu/awhcnhf7a4ax8qha5u1rwymkfaswmjz8?l=UPPER")
        XCTAssert(url?.policy == "https://example.com/.well-known/openpgpkey/policy")
    }

    func test_advanced_mode_uppercased_construct_URL_success() {
        let url = sut.construct(from: "UPPER@EXAMPLE.COM", method: .advanced)
        XCTAssert(url?.pubKeys == "https://openpgpkey.example.com/.well-known/openpgpkey/example.com/hu/awhcnhf7a4ax8qha5u1rwymkfaswmjz8?l=UPPER")
        XCTAssert(url?.policy == "https://openpgpkey.example.com/.well-known/openpgpkey/example.com/policy")
    }

    func test_construct_URL_failure() {
        XCTAssertNil(sut.construct(from: "examplemail.com", method: .advanced))
        XCTAssertNil(sut.construct(from: "example@", method: .advanced))
        XCTAssertNil(sut.construct(from: "@mail.com", method: .advanced))
        XCTAssertNil(sut.construct(from: "examplemail.com", method: .direct))
        XCTAssertNil(sut.construct(from: "example@", method: .direct))
        XCTAssertNil(sut.construct(from: "@mail.com", method: .direct))
    }
}
