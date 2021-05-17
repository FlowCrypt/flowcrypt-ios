//
//  ZBase32EncodingTests.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest

class ZBase32EncodingTests: XCTestCase {

    func testStringEncoding() throws {
        let inputString = "example@email.com"
        let encodedString = "cihgn5mopt1wy3mpcfwsamudp7so"

        XCTAssert(inputString.data().zBase32EncodedString() == encodedString)
    }
}
