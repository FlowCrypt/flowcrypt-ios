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
    func backupToInbox(key: KeyDetails) -> Promise<Void>
}

// MARK: - BackupService
struct BackupService {
    static let shared: BackupService = BackupService(
        backupProvider: Imap.shared,
        core: Core.shared,
        dataService: DataService.shared,
        imap: Imap.shared
    )

    let backupProvider: BackupProvider
    let core: Core
    let dataService: DataService
    let imap: Imap

    private var userID: UserId? {
        guard let email = dataService.email, email.isNotEmpty,
              let name = dataService.email, name.isNotEmpty
        else {
            return nil
        }
        return UserId(email: email, name: name)
    }
}

// MARK: - BackupServiceType
extension BackupService: BackupServiceType {
    func fetchBackups() -> Promise<[KeyDetails]> {
        Promise<[KeyDetails]> { resolve, reject in
            guard let email = self.dataService.email else {
                reject(BackupServiceError.emailNotFound)
                return
            }

            let backupData = try await(self.backupProvider.searchBackups(for: email))

            do {
                let parsed = try self.core.parseKeys(armoredOrBinary: backupData)
                let keys = parsed.keyDetails.filter { $0.private != nil }
                resolve(keys)
            } catch {
                reject(BackupServiceError.parse)
            }
        }
    }

    func backupToInbox(key: KeyDetails) -> Promise<Void> {
        Promise { () -> Void in
            guard let userId = self.userID else {
                throw BackupServiceError.emailNotFound
            }

            guard key.isFullyEncrypted ?? false else {
                throw BackupServiceError.keyIsNotFullyEncrypted
            }

            guard let privateKeyData = key.private?.data().base64EncodedString() else {
                fatalError() // !crash ok
            }

            let filename = "flowcrypt-backup-\(userId.email.userReadableEmail).key"
            let messageAttributes = [SendableMsg.Attribute(name: filename, type: "text/plain", base64: privateKeyData)]
            let message = SendableMsg(
                text: "setup_backup_email".localized,
                to: [userId.toMime],
                cc: [],
                bcc: [],
                from: userId.toMime,
                subject: "Your FlowCrypt Backup",
                replyToMimeMsg: nil,
                atts: messageAttributes
            )
            let backupEmail = try self.core.composeEmail(msg: message, fmt: .plain, pubKeys: nil)
            try await(imap.sendMail(mime: backupEmail.mimeEncoded))
        }
    }
}

// MARK: - Helpers
fileprivate extension String {
    var userReadableEmail: String {
        self.replacingOccurrences(
            of: "[^a-z0-9]",
            with: "",
            options: .regularExpression
        )
    }
}

fileprivate extension UserId {
    var toMime: String {
        "\(name) <\(email)>"
    }
}
