//
//  ZBase32EncodingTests.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 17.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest

class ZBase32EncodingTests: XCTestCase {

    func test_string_encoding() throws {
        let inputString = "example@email.com"
        let encodedString = "cihgn5mopt1wy3mpcfwsamudp7so"

        XCTAssert(
            String(decoding: inputString.data().zBase32EncodedBytes(), as: Unicode.UTF8.self) == encodedString
        )
    }
    
    func test_hashed_string_encoding() throws {
        let inputString = "example@email.com"
        let encodedString = "8dkp15twcw7feu1i8em784qtw91y3cs7"
        print(String(decoding: inputString.data().SHA1.zBase32EncodedBytes(), as: Unicode.UTF8.self))
        XCTAssert(
            String(decoding: inputString.data().SHA1.zBase32EncodedBytes(), as: Unicode.UTF8.self) == encodedString
        )
    }
}
