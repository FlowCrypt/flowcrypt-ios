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
        return isLoggedIn && (self.encryptedStorage.keys()?.count ?? 0) > 0
    }

    var isLoggedIn: Bool {
        currentAuthType != nil
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

    let encryptedStorage: EncryptedStorageType & LogOutHandler
    let localStorage: LocalStorageType & LogOutHandler

    private init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
    }
} 

extension DataService {
    var currentAuthType: AuthType? {
        // encrypted
        if let token = currentToken {
            return .oAuth(token)
        }
        if let user = encryptedStorage.getUser(), let userPassword = user.password  {
            return .password(userPassword)
        }
        return nil
    }
}

// MARK: - Data
extension DataService {
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

// MARK: - LogOut
extension DataService {
    func logOutAndDestroyStorage() {
        localStorage.logOut()
        encryptedStorage.logOut()
    }
}

// MARK: - DBMigration
extension DataService: DBMigration {
    func performMigrationIfNeeded() -> Promise<Void> {
        return Promise<Void> { [weak self] in
            guard let self = self else { throw AppErr.nilSelf }
            try await(self.encryptedStorage.performMigrationIfNeeded())
            self.performLocalMigration()
            self.performUserMigration()
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

    // TODO: ANTON - User migration
    private func performUserMigration() {
        guard let user = localStorage.currentUser() else {
            debugPrint("User migration not needed. User was not stored")
            return
        }

        guard let token = currentToken else {
            debugPrint("User migration not needed. Token was not stored")
            return
        }


    }
}
