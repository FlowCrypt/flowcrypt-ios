//
//  KeyDetailsTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 16.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class KeyDetailsTests: XCTestCase {

    func testHashable() {
        let keyDetail = KeyDetails(
            public: "public",
            private: "private",
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            ids: [
                KeyId(longid: "1", fingerprint: "1")
            ],
            created: 123,
            lastModified: 1,
            expiration: 2,
            users: [],
            algo: nil,
            revoked: false
        )
        
        let keyDetailWithSameKeyId = KeyDetails(
            public: "public2",
            private: "private2",
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            ids: [
                KeyId(longid: "1", fingerprint: "1")
            ],
            created: 123,
            lastModified: 1,
            expiration: 2,
            users: [],
            algo: nil,
            revoked: false
        )
        
        let set = Set([keyDetail, keyDetailWithSameKeyId])
        XCTAssert(set.count == 1)
    }
}
