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
        let keyDetails = KeyStorageMock.createFakeKeyDetails(expiration: nil, revoked: true)
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails])

        XCTAssertEqual(recipient.keyState, .revoked)
    }

    func testRecipientWithExpiredKey() {
        let expiration = Date().timeIntervalSince1970 - 60 * 60
        let keyDetails = KeyStorageMock.createFakeKeyDetails(expiration: Int(expiration))

        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails])
        XCTAssertEqual(recipient.keyState, .expired)
    }

    func testRecipientWithValidKey() {
        let expiration = Date().timeIntervalSince1970 + 60 * 60
        let keyDetails = KeyStorageMock.createFakeKeyDetails(expiration: Int(expiration))
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails])
        XCTAssertEqual(recipient.keyState, .active)

        let keyDetails2 = KeyStorageMock.createFakeKeyDetails(expiration: nil)
        let recipient2 = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [keyDetails2])
        XCTAssertEqual(recipient2.keyState, .active)
    }

    func testRecipientWithoutPubKey() {
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com", keyDetails: [])
        XCTAssertEqual(recipient.keyState, .empty)
    }

    func testRecipientKeysOrder() {
        let now = Int(Date().timeIntervalSince1970)
        let revokedKey = KeyStorageMock.createFakeKeyDetails(expiration: now + 1 * 3600, revoked: true)

        let activeKey1 = KeyStorageMock.createFakeKeyDetails(expiration: now + 1 * 3600)
        let activeKey2 = KeyStorageMock.createFakeKeyDetails(expiration: now + 2 * 3600)
        let activeKey3 = KeyStorageMock.createFakeKeyDetails(expiration: now + 3 * 3600)

        let nonExpiringKey = KeyStorageMock.createFakeKeyDetails(expiration: nil)
        let expiredKey = KeyStorageMock.createFakeKeyDetails(expiration: now - 1 * 3600)
        let oldExpiredKey = KeyStorageMock.createFakeKeyDetails(expiration: now - 2 * 3600)

        let keyDetails = [revokedKey, oldExpiredKey, activeKey1, expiredKey, activeKey2, nonExpiringKey, activeKey3]
        let recipient = RecipientWithSortedPubKeys(email: "test@test.com",
                                                   keyDetails: keyDetails)

        XCTAssertEqual(recipient.pubKeys[0].fingerprint, nonExpiringKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[1].fingerprint, activeKey3.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[2].fingerprint, activeKey2.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[3].fingerprint, activeKey1.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[4].fingerprint, expiredKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[5].fingerprint, oldExpiredKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[6].fingerprint, revokedKey.primaryFingerprint)
    }
}
