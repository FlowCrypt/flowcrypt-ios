//
//  DataService+DBMigration.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

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
