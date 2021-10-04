//
//  PrvKeyInfoTests.swift
//  FlowCryptAppTests
//
//  Created by Roma Sosnovsky on 04/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import XCTest
@testable import FlowCrypt

class PrvKeyInfoTests: XCTestCase {

    private let keyDetail = KeyDetails(
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
        algo: nil
    )

    private let user = UserObject(name: "name", email: "email", imap: nil, smtp: nil)

    func testInitFromKeyInfo() {
        let keyInfo = try! KeyInfo(keyDetail, passphrase: "123", source: .backup, user: user)
        let keyInfoWithoutPassphrase = try! KeyInfo(keyDetail, passphrase: nil, source: .backup, user: user)

        let privateKey1 = PrvKeyInfo(keyInfo: keyInfo, passphrase: nil)
        XCTAssertEqual(privateKey1.passphrase, "123")

        let privateKey2 = PrvKeyInfo(keyInfo: keyInfo, passphrase: "456")
        XCTAssertEqual(privateKey2.passphrase, "123")

        let privateKey3 = PrvKeyInfo(keyInfo: keyInfoWithoutPassphrase, passphrase: nil)
        XCTAssertEqual(privateKey3.passphrase, nil)

        let privateKey4 = PrvKeyInfo(keyInfo: keyInfoWithoutPassphrase, passphrase: "456")
        XCTAssertEqual(privateKey4.passphrase, "456")
    }

    func testCopyWithPassphrase() {
        let privateKey1 = PrvKeyInfo(private: "", longid: "", passphrase: nil, fingerprints: [])
        XCTAssertEqual(privateKey1.passphrase, nil)

        let privateKey2 = privateKey1.copy(with: "123")
        XCTAssertEqual(privateKey2.passphrase, "123")

        let privateKey3 = privateKey2.copy(with: "456")
        XCTAssertEqual(privateKey3.passphrase, "123")
    }
}
