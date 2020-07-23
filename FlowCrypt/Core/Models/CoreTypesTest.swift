//
//  CoreTypesTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import XCTest
import FlowCryptCommon

class CoreTypesTest: XCTestCase {

    func test_key_details_with_same_fingerprints() {
        let firstKeyDetail = KeyDetails(
            public: "public1",
            private: "private1",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [
                KeyId(
                    shortid: "shortid1",
                    longid: "longid",
                    fingerprint: "SAMEFINGERPRINT",
                    keywords: "keywords"
                )
            ],
            created: 0,
            users: []
        )
        let secondKeyDetail = KeyDetails(
            public: "public2",
            private: "private2",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [
                KeyId(
                    shortid: "shortid2",
                    longid: "longid2",
                    fingerprint: "SAMEFINGERPRINT",
                    keywords: "keywords2"
                )
            ],
            created: 0,
            users: []
        )

        let given: [KeyDetails] = [
            firstKeyDetail,
            secondKeyDetail
        ]

        let result = given.unique()

        XCTAssertEqual(
            result.count,
            1,
            "If the [KeyDetails] contains two keys with the same fingerprint, only one should be added"
        )

    }

    func test_key_ids_with_same_fingerprint() {
        let key1 = KeyId(
            shortid: "shortid1",
            longid: "longid1",
            fingerprint: "SAMEFINGERPRINT",
            keywords: "keywords1"
        )
        let key2 = KeyId(
            shortid: "shortid2",
            longid: "longid2",
            fingerprint: "SAMEFINGERPRINT",
            keywords: "keywords2"
        )
        let keys = [key1, key2]

        let result = keys.unique()

        XCTAssertEqual(result.count, 1)
    }
}
