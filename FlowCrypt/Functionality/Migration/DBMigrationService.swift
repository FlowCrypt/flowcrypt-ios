//
//  DBMigrationService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import RealmSwift

protocol DBMigration {
    func performMigrationIfNeeded() async throws
}

struct DBMigrationService {

    private let localStorage: LocalStorageType
    private let encryptedStorage: EncryptedStorageType

    private var storage: Realm { encryptedStorage.storage }

    init(localStorage: LocalStorageType, encryptedStorage: EncryptedStorageType) {
        self.localStorage = localStorage
        self.encryptedStorage = encryptedStorage
    }
}

// MARK: - DBMigration
extension DBMigrationService: DBMigration {
    func performMigrationIfNeeded() async throws {
    }
}
