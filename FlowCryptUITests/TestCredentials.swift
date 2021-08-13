//
//  Test.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 26/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import XCTest
import FlowCryptCommon

public let logger = Logger.nested("UI Tests")

class TestCredentials: XCTestCase {
    func test_user_credentials() {
        XCTAssert(UserCredentials.imapDev.email == "default@flowcrypt.test")
        XCTAssert(UserCredentials.gmailDev.email == "ci.tests.gmail@flowcrypt.dev")
    }
}
