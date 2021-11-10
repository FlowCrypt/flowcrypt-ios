//
//  KeyStorageMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

class KeyStorageMock: KeyStorageType {
    func addKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
    }

    var publicKeyResult: (() -> (String?))!
    func publicKey() -> String? {
        publicKeyResult()
    }

    var keysInfoResult: (() -> ([KeyInfo]))!
    func keysInfo() -> [KeyInfo] {
        keysInfoResult()
    }
}

extension KeyStorageMock {
    static func createFakeKeyDetails(pub: String = "pubKey", expiration: Int?, revoked: Bool = false) -> KeyDetails {
        KeyDetails(
            public: pub,
            private: nil,
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [KeyId(longid: String.random(length: 40),
                        fingerprint: String.random(length: 40))],
            created: 1,
            lastModified: nil,
            expiration: expiration,
            users: ["Test User <test@flowcrypt.com>"],
            algo: nil,
            revoked: revoked
        )
    }
}
