//
//  DBMigrationService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.02.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import RealmSwift

protocol DBMigration {
    func performMigrationIfNeeded() -> Promise<Void>
}

struct DBMigrationService {
    private var storage: Realm { encryptedStorage.storage }
    private let localStorage: LocalStorageType
    private let encryptedStorage: EncryptedStorageType

    init(localStorage: LocalStorageType, encryptedStorage: EncryptedStorageType) {
        self.localStorage = localStorage
        self.encryptedStorage = encryptedStorage
    }
}

// MARK: - DBMigration
extension DBMigrationService: DBMigration {
    func performMigrationIfNeeded() -> Promise<Void> {
        Promise<Void> {
            self.performTokenEncryptedMigration()
            self.performUserSessionMigration()
            self.performGmailApiMigration()
        }
    }
}

// MARK: Token
extension DBMigrationService {
    /// Perform migration for users which has token saved in non encrypted storage
    private func performTokenEncryptedMigration() {
        let legacyTokenIndex = "keyCurrentToken"
        guard previouslyStoredUser() != nil else {
            debugPrint("Local migration not needed. User was not stored in local storage")
            return
        }
        guard let token = localStorage.storage.string(forKey: legacyTokenIndex) else {
            debugPrint("Local migration not needed. Token was not saved in local storage")
            return
        }

        performSessionMigration(with: token)
        localStorage.storage.removeObject(forKey: legacyTokenIndex)
    }
}

// MARK: User session
extension DBMigrationService {
    /// Perform migration from google signing to generic session
    private func performUserSessionMigration() {
        guard let token = encryptedStorage.currentToken() else {
            debugPrint("User migration not needed. Token was not stored or migration already finished")
            return
        }

        performSessionMigration(with: token)
    }

    private func performSessionMigration(with token: String) {
        guard let user = previouslyStoredUser() else {
            debugPrint("User migration not needed. User was not stored or migration already finished")
            return
        }
        debugPrint("Perform user migration for token")
        let userObject = UserObject.googleUser(name: user.name, email: user.email, token: token)

        encryptedStorage.saveUser(with: userObject)
        UserDefaults.standard.set(nil, forKey: legacyCurrentUserIndex)
    }

    var legacyCurrentUserIndex: String { "keyCurrentUser" }
    private func previouslyStoredUser() -> User? {
        guard let data = UserDefaults.standard.object(forKey: legacyCurrentUserIndex) as? Data else { return nil }
        return try? PropertyListDecoder().decode(User.self, from: data)
    }
}

// MARK: Gmail Api
extension DBMigrationService {
    /// Perform migration when Gmail Api implemented
    private func performGmailApiMigration() {
        let key = "KeyGmailApiMigration"
        let isMigrated = UserDefaults.standard.bool(forKey: key)
        guard !isMigrated else {
            return
        }
        UserDefaults.standard.set(true, forKey: key)
        let folders = storage.objects(FolderObject.self)

        do {
            try storage.write {
                storage.delete(folders)
            }
        } catch let error {
            assertionFailure("Can't perform Gmail Api migration \(error)")
        }
    }
}
