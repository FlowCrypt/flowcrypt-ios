//
//  KeyDetailsTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 16.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class KeyDetailsTests: XCTestCase {

    let user = UserRealmObject(name: "name", email: "email", imap: nil, smtp: nil)

    func testInitWithEmptyPrivateThrowsError() {
        let keyDetail = KeyDetails(
            public: "public",
            private: nil,
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            usableForEncryption: true,
            usableForSigning: true,
            ids: [
                KeyId(longid: "longId", fingerprint: "fingerprint")
            ],
            created: 1_231_244,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )

        try assert(
            KeypairRealmObject(keyDetail, passphrase: nil, source: .backup, user: user),
            throws: KeypairError.missingPrivateKey("storing pubkey as private")
        )
    }

    func testInitNotFullyEcryptedThrowsError() {
        let keyDetail = KeyDetails(
            public: "public",
            private: "private",
            isFullyDecrypted: true,
            isFullyEncrypted: false,
            usableForEncryption: true,
            usableForSigning: true,
            ids: [
                KeyId(longid: "longId", fingerprint: "fingerprint")
            ],
            created: 1_231_244,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )

        try assert(
            KeypairRealmObject(keyDetail, passphrase: nil, source: .backup, user: user),
            throws: KeypairError.notEncrypted("Will not store Private Key that is not fully encrypted")
        )
    }

    func testWithEmptyKeyIdsThrowsError() {
        let keyDetail = KeyDetails(
            public: "public",
            private: "private",
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            usableForEncryption: true,
            usableForSigning: true,
            ids: [],
            created: 1_231_244,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )

        try assert(
            KeypairRealmObject(keyDetail, passphrase: nil, source: .backup, user: user),
            throws: KeypairError.missingKeyIds
        )
    }

    func testInit() throws {
        let keyDetail = KeyDetails(
            public: "public",
            private: "private",
            isFullyDecrypted: false,
            isFullyEncrypted: true,
            usableForEncryption: true,
            usableForSigning: true,
            ids: [
                KeyId(longid: "l1", fingerprint: "f1"),
                KeyId(longid: "l2", fingerprint: "f2"),
                KeyId(longid: "l3", fingerprint: "f3")
            ],
            created: 100,
            lastModified: 100,
            expiration: nil,
            users: ["example@test.com"],
            algo: nil,
            revoked: false
        )

        let key = try KeypairRealmObject(keyDetail, passphrase: "123", source: .backup, user: user)

        XCTAssertTrue(key.private == "private")
        XCTAssertTrue(key.public == "public")
        XCTAssertTrue(Array(key.allFingerprints) == ["f1", "f2", "f3"])
        XCTAssertTrue(Array(key.allLongids) == ["l1", "l2", "l3"])
        XCTAssertTrue(key.passphrase == "123")
        XCTAssertTrue(key.source == "backup")
        XCTAssertTrue(key.user == user)
        XCTAssertTrue(key.primaryFingerprint == "f1")
        XCTAssertTrue(key.primaryLongid == "l1")

        XCTAssertTrue(key.user?.email == "email")
    }
}
