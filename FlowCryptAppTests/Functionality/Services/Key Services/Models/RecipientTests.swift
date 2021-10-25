//
//  RecipientTests.swift
//  FlowCryptAppTests
//
//  Created by Roma Sosnovsky on 22/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class RecipientTests: XCTestCase {
    private let calendar = Calendar.current

    func testRecipientWithRevokedKey() {
        let keyDetails = generateKey(expiration: nil, revoked: true)
        let recipient = RecipientWithPubKeys(email: "test@test.com", keyDetails: [keyDetails])

        XCTAssertEqual(recipient.keyState, .revoked)
    }

    func testRecipientWithExpiredKey() {
        let expiration = Date().timeIntervalSince1970 - 60 * 60
        let keyDetails = generateKey(expiration: Int(expiration), revoked: false)

        let recipient = RecipientWithPubKeys(email: "test@test.com", keyDetails: [keyDetails])
        XCTAssertEqual(recipient.keyState, .expired)
    }

    func testRecipientWithValidKey() {
        let expiration = Date().timeIntervalSince1970 + 60 * 60
        let keyDetails = generateKey(expiration: Int(expiration), revoked: false)
        let recipient = RecipientWithPubKeys(email: "test@test.com", keyDetails: [keyDetails])
        XCTAssertEqual(recipient.keyState, .active)

        let keyDetails2 = generateKey(expiration: nil, revoked: false)
        let recipient2 = RecipientWithPubKeys(email: "test@test.com", keyDetails: [keyDetails2])
        XCTAssertEqual(recipient2.keyState, .active)
    }

    func testRecipientWithoutPubKey() {
        let recipient = RecipientWithPubKeys(email: "test@test.com", keyDetails: [])
        XCTAssertEqual(recipient.keyState, .empty)
    }
}

extension RecipientTests {
    private func generateKey(expiration: Int?, revoked: Bool) -> KeyDetails {
        KeyDetails(
            public: "Public part",
            private: nil,
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [
                KeyId(longid: "longid", fingerprint: "fingerprint")
            ],
            created: 1,
            lastModified: nil,
            expiration: expiration,
            users: [],
            algo: nil,
            revoked: revoked
        )
    }
}
