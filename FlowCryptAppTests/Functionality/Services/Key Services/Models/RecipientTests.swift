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

    func testRecipientWithRevokedKey() throws {
        let recipient = try createRecipient(keyExpiration: nil, isKeyRevoked: true)
        XCTAssertEqual(recipient.keyState, .revoked)
    }

    func testRecipientWithExpiredKey() throws {
        let expiration = Date().timeIntervalSince1970 - 60 * 60
        let recipient = try createRecipient(keyExpiration: Int(expiration))
        XCTAssertEqual(recipient.keyState, .expired)
    }

    func testRecipientWithValidKey() throws {
        let expiration = Date().timeIntervalSince1970 + 60 * 60
        let recipient = try createRecipient(keyExpiration: Int(expiration))
        XCTAssertEqual(recipient.keyState, .active)
        XCTAssertEqual(recipient.pubKeys.first?.emails, ["test@flowcrypt.com"])

        let recipient2 = try createRecipient(keyExpiration: nil)
        XCTAssertEqual(recipient2.keyState, .active)
    }

    func testRecipientWithoutPubKey() throws {
        let recipient = try RecipientWithSortedPubKeys(
            Recipient(email: "test@flowcrypt.com"),
            keyDetails: []
        )
        XCTAssertEqual(recipient.keyState, .empty)
    }

    func testRecipientKeysOrder() throws {
        let now = Int(Date().timeIntervalSince1970)
        let revokedKey = EncryptedStorageMock.createFakeKeyDetails(expiration: now + 1 * 3600, revoked: true)

        let activeKey1 = EncryptedStorageMock.createFakeKeyDetails(expiration: now + 1 * 3600)
        let activeKey2 = EncryptedStorageMock.createFakeKeyDetails(expiration: now + 2 * 3600)
        let activeKey3 = EncryptedStorageMock.createFakeKeyDetails(expiration: now + 3 * 3600)

        let nonExpiringKey = EncryptedStorageMock.createFakeKeyDetails(expiration: nil)
        let expiredKey = EncryptedStorageMock.createFakeKeyDetails(expiration: now - 1 * 3600)
        let oldExpiredKey = EncryptedStorageMock.createFakeKeyDetails(expiration: now - 2 * 3600)

        let keyDetails = [revokedKey, oldExpiredKey, activeKey1, expiredKey, activeKey2, nonExpiringKey, activeKey3]
        let recipient = try RecipientWithSortedPubKeys(
            Recipient(email: "test@flowcrypt.com"),
            keyDetails: keyDetails
        )

        XCTAssertEqual(recipient.pubKeys[0].fingerprint, try nonExpiringKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[1].fingerprint, try activeKey3.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[2].fingerprint, try activeKey2.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[3].fingerprint, try activeKey1.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[4].fingerprint, try expiredKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[5].fingerprint, try oldExpiredKey.primaryFingerprint)
        XCTAssertEqual(recipient.pubKeys[6].fingerprint, try revokedKey.primaryFingerprint)
    }

    private func createRecipient(keyExpiration: Int?, isKeyRevoked: Bool = false) throws -> RecipientWithSortedPubKeys {
        let keyDetails = EncryptedStorageMock.createFakeKeyDetails(
            expiration: keyExpiration,
            revoked: isKeyRevoked
        )
        let recipient = Recipient(email: "test@flowcrypt.com")
        return try RecipientWithSortedPubKeys(recipient, keyDetails: [keyDetails])
    }
}
