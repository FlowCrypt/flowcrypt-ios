//
//  DataManager.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol DataManagerType {
    func startFor(user: User, with token: String?)
    
    var email: String? { get }
    var currentUser: User? { get }
    var currentToken: String? { get }

    var isSessionValid: Bool { get }
    var isLoggedIn: Bool { get }

    func keys() -> [PrvKeyInfo]?
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func publicKey() -> String?

    func logOutAndDestroyStorage()
}

final class DataManager: DataManagerType {
    static let shared = DataManager()

    var isLoggedIn: Bool {
        let isUserStored = currentUser != nil && currentToken != nil
        let hasKey = (self.encryptedStorage.keys()?.count ?? 0) > 0
        return isUserStored && hasKey
    }

    var isSessionValid: Bool {
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

extension DataManager {
    func logOutAndDestroyStorage() {
        localStorage.logOut()
        encryptedStorage.logOut()
    }
}

extension DataManager: DBMigration {
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
