//
//  PasswordProtectedMsgTest.swift
//  FlowCryptTests
//
//  Created by Ioan Moldovan on 20.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class PasswordProtectedMsgTest: XCTestCase {

    func testPasswordProtectedMessageCompliance() {
        let disallowTerms = ["[Classification: Data Control: Internal Data Control]", "droid", "forbidden data"]

        let subjectsToTest: [String: Bool] = [
            "[Classification: Data Control: Internal Data Control] Quarter results": false,
            "Conference information [Classification: Data Control: Internal Data Control]": false,
            "Classification: Data Control: Internal Data Control - Tomorrow meeting": true,
            "Internal Data Control - Finance monitoring": true,
            "Android phone update": true,
            "droid phone": false,
            "DROiD phone": false,
            "[forbidden data] year results": false,
        ]

        for (subject, expectedValue) in subjectsToTest {
            let result = subject.isPasswordMessageEnabled(disallowTerms: disallowTerms)
            XCTAssertEqual(result, expectedValue, "Failed for subject: \(subject)")
        }
    }
}
