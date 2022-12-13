//
//  KeyMethodsTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 20.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class KeyMethodsTest: XCTestCase {

    var sut: KeyMethods!
    var passPhrase = "Some long phrase"

    override func setUp() {
        sut = KeyMethods()
    }

    func testEmptyParsingKey() async throws {
        let emptyKeys: [KeyDetails] = []
        let result = try await sut.filterByPassPhraseMatch(keys: emptyKeys, passPhrase: passPhrase)

        XCTAssertTrue(result.isEmpty)
    }

    func testPassPublicKeyWhenExpectingPrivateForPassPhraseMatch() async throws {
        // private part = nil
        let keys = [
            KeyDetails(
                public: "Public part",
                private: nil,
                isFullyDecrypted: false,
                isFullyEncrypted: false,
                usableForEncryption: true,
                ids: [
                    KeyId(longid: "longid", fingerprint: "fingerprint")
                ],
                created: 1,
                lastModified: nil,
                expiration: nil,
                users: [],
                algo: nil,
                revoked: false
            ),
            KeyDetails(
                public: "Public part2",
                private: nil,
                isFullyDecrypted: false,
                isFullyEncrypted: false,
                usableForEncryption: true,
                ids: [
                    KeyId(longid: "longid 2", fingerprint: "fingerprint 2")
                ],
                created: 1,
                lastModified: nil,
                expiration: nil,
                users: [],
                algo: nil,
                revoked: false
            )
        ]
        do {
            _ = try await sut.filterByPassPhraseMatch(keys: keys, passPhrase: passPhrase)
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? KeypairError, KeypairError.expectedPrivateGotPublic)
        }
    }
}

extension KeyMethodsTest {
    var validKeys: [KeyDetails] { [
        KeyDetails(
            public: "Public part",
            private: "private 1",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            usableForEncryption: true,
            ids: [
                KeyId(longid: "longid", fingerprint: "fingerprint")
            ],
            created: 1,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        ),
        KeyDetails(
            public: "Public part2",
            private: "private 2",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            usableForEncryption: true,
            ids: [
                KeyId(longid: "longid2", fingerprint: "fingerprint2")
            ],
            created: 1,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )
    ] }
}
