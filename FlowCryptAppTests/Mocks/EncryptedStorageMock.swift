//
//  EncryptedStorageMock.swift
//  FlowCryptAppTests
//
//  Created by  Ivan Ushakov on 01.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import RealmSwift

final class EncryptedStorageMock: EncryptedStorageType {

    var storage: Realm {
        fatalError()
    }

    var activeUser: FlowCrypt.User?

    var getAllUsersResult: [FlowCrypt.User] = []
    func getAllUsers() -> [FlowCrypt.User] {
        getAllUsersResult
    }

    func saveActiveUser(with user: FlowCrypt.User) {
    }

    var doesAnyKeypairExistResult = false
    func doesAnyKeypairExist(for email: String) -> Bool {
        doesAnyKeypairExistResult
    }

    func putKeypairs(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
    }

    var getKeypairsResult: [Keypair] = []
    func getKeypairs(by email: String) -> [Keypair] {
        getKeypairsResult
    }

    func mockGetKeyPairs(with fingerPrints: [String]) throws {
        let expiration = Int(Date().timeIntervalSince1970) + 3600
        getKeypairsResult = try fingerPrints.map { fingerPrint in
            try Keypair(
                EncryptedStorageMock.createFakeKeyDetails(
                    prv: "private",
                    expiration: expiration,
                    fingerprint: fingerPrint,
                    isFullyEncrypted: true
                ),
                passPhrase: nil,
                source: "test"
            )
        }
    }

    func validate() throws {
    }

    static func removeStorageFile() throws {
    }

    func cleanup() {
    }
}

extension EncryptedStorageMock {
    static func createFakeKeyDetails(pub: String = "pubKey", prv: String? = nil, expiration: Int?, revoked: Bool = false, fingerprint: String? = nil, isFullyEncrypted: Bool? = false) -> KeyDetails {
        KeyDetails(
            public: pub,
            private: prv,
            isFullyDecrypted: false,
            isFullyEncrypted: isFullyEncrypted,
            ids: [KeyId(longid: String.random(length: 40),
                        fingerprint: fingerprint ?? String.random(length: 40))],
            created: 1,
            lastModified: Int(Date().timeIntervalSince1970),
            expiration: expiration,
            users: ["Test User <test@flowcrypt.com>"],
            algo: nil,
            revoked: revoked
        )
    }
}
