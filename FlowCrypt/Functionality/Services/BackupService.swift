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
    func backupToInbox(key: KeyDetails, userId: UserId) -> Promise<Void>
}

// MARK: - BackupService
struct BackupService {
    static let shared: BackupService = BackupService(
        backupProvider: Imap.shared,
        core: Core.shared,
        dataService: DataService.shared,
        imap: Imap.shared
    )

    enum BackupError: Error {
        case parse
        case emailNotFound

        // "Private Key must be fully enrypted before backing up"
        // TODO: - ANTON - Error message
        case keyIsNotFullyEncrypted
    }

    let backupProvider: BackupProvider
    let core: Core
    let dataService: DataService
    let imap: Imap
}

// MARK: - BackupServiceType
extension BackupService: BackupServiceType {
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

    func backupToInbox(key: KeyDetails, userId: UserId) -> Promise<Void> {
        Promise { () -> Void in
            guard key.isFullyEncrypted ?? false else { throw BackupError.keyIsNotFullyEncrypted }

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
