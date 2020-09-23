//
//  BackupService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

protocol BackupServiceType {
    func fetchBackups() -> Promise<[KeyDetails]>
}

struct BackupService: BackupServiceType {
    static let shared: BackupService = BackupService(
        backupProvider: Imap.shared,
        core: Core.shared,
        dataService: DataService.shared
    )

    enum BackupError: Error {
        case parse, emailNotFound
    }
    let backupProvider: BackupProvider
    let core: Core
    let dataService: DataService

    func fetchBackups() -> Promise<[KeyDetails]> {
        Promise<[KeyDetails]> { resolve, reject in
            guard let email = self.dataService.email else {
                reject(BackupError.emailNotFound)
                return
            }

            let backupData = try await(self.backupProvider.searchBackups(for: email))

            do {
                let parsed = try self.core.parseKeys(armoredOrBinary: backupData)
                let keys = parsed.keyDetails.filter { $0.private != nil }
                resolve(keys)
            } catch {
                reject(BackupError.parse)
            }
        }
    }
}
