//
//  DBMigrationService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.02.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
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

    private let logger = Logger.nested(in: Self.self, with: .migration)

    init(localStorage: LocalStorageType, encryptedStorage: EncryptedStorageType) {
        self.localStorage = localStorage
        self.encryptedStorage = encryptedStorage
    }
}

// MARK: - DBMigration
extension DBMigrationService: DBMigration {
    func performMigrationIfNeeded() -> Promise<Void> {
        Promise<Void> {
            // self.performGmailApiMigration()
        }
    }
}

// MARK: - Migration example
// Perform migration when Gmail Api implemented
// remove after some real migration will be implemented
extension DBMigrationService {
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
        } catch {
            logger.logWarning("Can't perform Gmail Api migration \(error)")
            assertionFailure("Can't perform Gmail Api migration \(error)")
        }
    }
}
