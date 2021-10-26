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
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails])

        XCTAssertEqual(recipient.keyState, .revoked)
    }

    func testRecipientWithExpiredKey() {
        let expiration = Date().timeIntervalSince1970 - 60 * 60
        let keyDetails = generateKey(expiration: Int(expiration), revoked: false)

        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails])
        XCTAssertEqual(recipient.keyState, .expired)
    }

    func testRecipientWithValidKey() {
        let expiration = Date().timeIntervalSince1970 + 60 * 60
        let keyDetails = generateKey(expiration: Int(expiration), revoked: false)
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails])
        XCTAssertEqual(recipient.keyState, .active)

        let keyDetails2 = generateKey(expiration: nil, revoked: false)
        let recipient2 = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails2])
        XCTAssertEqual(recipient2.keyState, .active)
    }

    func testRecipientWithoutPubKey() {
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [])
        XCTAssertEqual(recipient.keyState, .empty)
    }

    func testRecipientKeysOrder() {
        let revokedKey = generateKey(expiration: Int(Date().timeIntervalSince1970 + 60 * 60), revoked: true)

        let activeKey1 = generateKey(expiration: Int(Date().timeIntervalSince1970 + 60 * 60))
        let activeKey2 = generateKey(expiration: Int(Date().timeIntervalSince1970 + 48 * 60 * 60))
        let activeKey3 = generateKey(expiration: Int(Date().timeIntervalSince1970 + 24 * 60 * 60))

        let nonExpiringKey = generateKey(expiration: nil)
        let expiredKey = generateKey(expiration: Int(Date().timeIntervalSince1970 - 60 * 60))
        let oldExpiredKey = generateKey(expiration: Int(Date().timeIntervalSince1970 - 24 * 60 * 60))

        let keyDetails = [revokedKey, oldExpiredKey, activeKey1, expiredKey, activeKey2, nonExpiringKey, activeKey3]
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com",
                                                   keyDetails: keyDetails)

        XCTAssertEqual(recipient.pubKeys[0].fingerprint, nonExpiringKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[1].fingerprint, activeKey2.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[2].fingerprint, activeKey3.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[3].fingerprint, activeKey1.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[4].fingerprint, expiredKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[5].fingerprint, oldExpiredKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[6].fingerprint, revokedKey.primaryFingerprint)
    }
}

extension RecipientTests {
    private func generateKey(expiration: Int?, revoked: Bool = false) -> KeyDetails {
        KeyDetails(
            public: "Public part",
            private: nil,
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [KeyId(longid: randomString(length: 16),
                        fingerprint: randomString(length: 16))],
            created: 1,
            lastModified: nil,
            expiration: expiration,
            users: [],
            algo: nil,
            revoked: revoked
        )
    }

    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
