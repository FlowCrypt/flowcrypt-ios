//
//  Test.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 26/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import XCTest

class TestCredentials: XCTestCase {
    func test_user_credentials() {
        XCTAssert(UserCredentials.main != UserCredentials.empty)
        XCTAssert(UserCredentials.noKeyBackUp != UserCredentials.empty)
        XCTAssert(UserCredentials.compatibility != UserCredentials.empty)

        XCTAssert(!UserCredentials.noKeyBackUp.privateKey.isEmpty)
    }
}
