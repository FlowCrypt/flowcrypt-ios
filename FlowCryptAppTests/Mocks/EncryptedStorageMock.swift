//
//  EncryptedStorageMock.swift
//  FlowCryptAppTests
//
//  Created by  Ivan Ushakov on 01.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
@testable import FlowCrypt
import RealmSwift

final class EncryptedStorageMock: EncryptedStorageType {

    var storage: Realm {
        get throws {
            return try Realm()
        }
    }

    var activeUser: FlowCrypt.User?

    var getAllUsersResult: [FlowCrypt.User] = []
    func getAllUsers() -> [FlowCrypt.User] {
        getAllUsersResult
    }

    func saveActiveUser(with user: FlowCrypt.User) {}

    var doesAnyKeypairExistResult = false
    func doesAnyKeypairExist(for email: String) -> Bool {
        doesAnyKeypairExistResult
    }

    func putKeypairs(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {}

    var getKeypairsResult: [Keypair] = []
    func getKeypairs(by email: String) -> [Keypair] {
        getKeypairsResult
    }

    func validate() throws {}

    static func removeStorageFile() throws {}

    func cleanup() {}

    func removeKeypairs(keypairs: [Keypair]) throws {}

    func deleteAccount(email: String) throws {}
}

extension EncryptedStorageMock {
    static func createFakeKeyDetails(pub: String = "pubKey", expiration: Int?, revoked: Bool = false) -> KeyDetails {
        KeyDetails(
            public: pub,
            private: nil,
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            usableForEncryption: true,
            usableForSigning: true,
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
