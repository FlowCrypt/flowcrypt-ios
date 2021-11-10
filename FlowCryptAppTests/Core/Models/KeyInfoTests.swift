//
//  KeyInfoTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 09.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class KeyInfoTests: XCTestCase {

    let user = UserRealmObject(name: "name", email: "email", imap: nil, smtp: nil)

    func testKeyInfoInitWithEmptyPrivateThrowsError() {
        let keyDetail = KeyDetails(
            public: "public",
            private: nil,
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            ids: [
                KeyId(longid: "longId", fingerprint: "fingerprint")
            ],
            created: 1231244,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )

        var thrownError: Error?
        XCTAssertThrowsError(try KeyInfoRealmObject(keyDetail, passphrase: nil, source: .backup, user: user)) { error in
            thrownError = error
        }

        XCTAssertTrue(thrownError is KeyInfoError)
    }

    func testKeyInfoInitNotFullyEcryptedThrowsError() {
        let keyDetail = KeyDetails(
            public: "public",
            private: "private",
            isFullyDecrypted: true,
            isFullyEncrypted: false,
            ids: [
                KeyId(longid: "longId", fingerprint: "fingerprint")
            ],
            created: 1231244,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )

        var thrownError: Error?
        XCTAssertThrowsError(try KeyInfoRealmObject(keyDetail, passphrase: nil, source: .backup, user: user)) { error in
            thrownError = error
        }

        XCTAssertTrue(thrownError is KeyInfoError)
    }

    func testKeyInfoWithEmptyKeyIdsThrowsError() {
        let keyDetail = KeyDetails(
            public: "public",
            private: "private",
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            ids: [ ],
            created: 1231244,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )

        var thrownError: Error?
        XCTAssertThrowsError(try KeyInfoRealmObject(keyDetail, passphrase: nil, source: .backup, user: user)) { error in
            thrownError = error
        }

        XCTAssertTrue(thrownError is KeyInfoError)
    }

    func testKeyInfoInit() throws {
        let keyDetail = KeyDetails(
            public: "public",
            private: "private",
            isFullyDecrypted: true,
            isFullyEncrypted: true,
            ids: [
                KeyId(longid: "l1", fingerprint: "f1"),
                KeyId(longid: "l2", fingerprint: "f2"),
                KeyId(longid: "l3", fingerprint: "f3")
            ],
            created: 1231244,
            lastModified: nil,
            expiration: nil,
            users: [ ],
            algo: nil,
            revoked: false
        )

        let key = try KeyInfoRealmObject(keyDetail, passphrase: "123", source: .backup, user: user)

        XCTAssertTrue(key.private == "private")
        XCTAssertTrue(key.public == "public")
        XCTAssertTrue(Array(key.allFingerprints) == ["f1", "f2", "f3"])
        XCTAssertTrue(Array(key.allLongids) == ["l1", "l2", "l3"])
        XCTAssertTrue(key.passphrase == "123")
        XCTAssertTrue(key.source == "backup")
        XCTAssertTrue(key.user == user)
        XCTAssertTrue(key.primaryFingerprint == "f1")
        XCTAssertTrue(key.primaryLongid == "l1")

        XCTAssertTrue(KeyInfoRealmObject.primaryKey() == "primaryFingerprint")
        XCTAssertTrue(key.account == "email")
    }
}
