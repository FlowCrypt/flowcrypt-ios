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

    func addKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
    }

    var getKeypairsResult: [KeyInfo] = []
    func getKeypairs(by email: String) -> [KeyInfo] {
        getKeypairsResult
    }

    func validate() throws {
    }

    func reset() throws {
    }

    func cleanup() {
    }
}

extension EncryptedStorageMock {
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
