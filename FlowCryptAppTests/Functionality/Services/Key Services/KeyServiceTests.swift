//
//  KeyServiceTests.swift
//  FlowCryptAppTests
//
//  Created by  Ivan Ushakov on 15.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import XCTest
@testable import FlowCrypt

final class KeyServiceTests: XCTestCase {

    func testGetSigningKeyFirstEmail() throws {
        // arrange
        let keyStorage = KeyStorageMock()
        let keyInfo = KeyInfo()
        keyInfo.user = UserObject(name: "Bill", email: "bill@test.com", imap: nil, smtp: nil)
        keyStorage.keysInfoResult = {
            [keyInfo]
        }

        let passPhraseService = PassPhraseServiceMock()
        passPhraseService.passPhrases = [
            PassPhrase(value: "phrase", fingerprints: ["2"], date: nil)
        ]

        let userEmail = "bill@test.com"

        let keyDetails_1 = KeyDetails(
            public: "public1",
            private: "private1",
            isFullyDecrypted: nil,
            isFullyEncrypted: nil,
            ids: [KeyId(longid: "1", fingerprint: "1")],
            created: 0,
            lastModified: nil,
            expiration: nil,
            users: ["Joe <joe@example.com>", "Bill <bill@test.com>"],
            algo: nil
        )
        let keyDetails_2 = KeyDetails(
            public: "public2",
            private: "private2",
            isFullyDecrypted: nil,
            isFullyEncrypted: nil,
            ids: [KeyId(longid: "2", fingerprint: "2")],
            created: 0,
            lastModified: nil,
            expiration: nil,
            users: ["Bill <bill@test.com>", "Jim <jim@example.com>"],
            algo: nil
        )
        let keyParser: KeyService.KeyParser = { data in
            return CoreRes.ParseKeys(
                format: .armored,
                keyDetails: [keyDetails_1, keyDetails_2]
            )
        }

        let keyService = KeyService(
            keyParser: keyParser,
            storage: keyStorage,
            passPhraseService: passPhraseService,
            currentUserEmail: userEmail
        )

        // act
        let result = try keyService.getSigningKey()

        // assert
        XCTAssertEqual(result?.private, "private2")
        XCTAssertEqual(result?.passphrase, "phrase")
    }

    func testGetSigningKeyNotFirstEmail() throws {
        // arrange
        let keyStorage = KeyStorageMock()
        let keyInfo = KeyInfo()
        keyInfo.user = UserObject(name: "Bill", email: "bill@test.com", imap: nil, smtp: nil)
        keyStorage.keysInfoResult = {
            [keyInfo]
        }

        let passPhraseService = PassPhraseServiceMock()
        let userEmail = "bill@test.com"

        let keyDetails = KeyDetails(
            public: "public1",
            private: "private1",
            isFullyDecrypted: nil,
            isFullyEncrypted: nil,
            ids: [KeyId(longid: "1", fingerprint: "1")],
            created: 0,
            lastModified: nil,
            expiration: nil,
            users: ["Joe <joe@example.com>", "Bill <bill@test.com>"],
            algo: nil
        )
        let keyParser: KeyService.KeyParser = { data in
            return CoreRes.ParseKeys(
                format: .armored,
                keyDetails: [keyDetails]
            )
        }

        let keyService = KeyService(
            keyParser: keyParser,
            storage: keyStorage,
            passPhraseService: passPhraseService,
            currentUserEmail: userEmail
        )

        // act
        let result = try keyService.getSigningKey()

        // assert
        XCTAssertEqual(result?.private, "private1")
        XCTAssertNil(result?.passphrase)
    }
}
