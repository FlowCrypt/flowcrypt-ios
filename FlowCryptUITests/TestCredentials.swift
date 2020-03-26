//
//  Test.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 26/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import XCTest

class TestCredentials: XCTestCase {

    func testExample() {
        XCTAssert(UserCredentials.main != UserCredentials.empty)
        XCTAssert(UserCredentials.noKeyBackUp != UserCredentials.empty)
    }

}
