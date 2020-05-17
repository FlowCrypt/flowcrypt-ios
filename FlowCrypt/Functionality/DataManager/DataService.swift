//
//  DataService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol DataServiceType {
    func startFor(user: User, with token: String?)

    var email: String? { get }
    var currentUser: User? { get }
    var currentToken: String? { get }

    var isLoggedIn: Bool { get }
    var isSetupFinished: Bool { get }

    func keys() -> [PrvKeyInfo]?
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func publicKey() -> String?

    func logOutAndDestroyStorage()
}

final class DataService: DataServiceType {
    static let shared = DataService()

    var isSetupFinished: Bool {
        return isLoggedIn && (encryptedStorage.keys()?.count ?? 0) > 0
    }

    var isLoggedIn: Bool {
        currentToken != nil && currentUser != nil
    }

    var email: String? {
        currentUser?.email
    }

    var currentUser: User? {
        localStorage.currentUser()
    }

    var currentToken: String? {
        encryptedStorage.currentToken()
    }

    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private let localStorage: LocalStorageType & LogOutHandler

    private init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
    }

    func keys() -> [PrvKeyInfo]? {
        guard let keys = encryptedStorage.keys() else { return nil }
        return Array(keys)
            .map(PrvKeyInfo.init)
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.addKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
    }

    func publicKey() -> String? {
        encryptedStorage.publicKey()
    }

    func startFor(user: User, with token: String?) {
        if currentUser != user, currentUser != nil {
            logOutAndDestroyStorage()
        }
        localStorage.saveCurrentUser(user: user)
        encryptedStorage.saveToken(with: token)
    }
}

extension DataService {
    func logOutAndDestroyStorage() {
        localStorage.logOut()
        encryptedStorage.logOut()
    }
}

extension DataService: DBMigration {
    func performMigrationIfNeeded() -> Promise<Void> {
        return Promise<Void> { [weak self] in
            guard let self = self else { throw AppErr.nilSelf }
            try await(self.encryptedStorage.performMigrationIfNeeded())
            self.performLocalMigration()
        }
    }

    private func performLocalMigration() {
        let legacyTokenIndex = "keyCurrentToken"
        guard localStorage.currentUser() != nil else {
            debugPrint("Local migration not needed. User was not stored")
            return
        }
        guard let token = localStorage.storage.string(forKey: legacyTokenIndex) else {
            debugPrint("Local migration not needed. Token was not saved")
            return
        }
        encryptedStorage.saveToken(with: token)
        localStorage.storage.removeObject(forKey: legacyTokenIndex)
    }
}
