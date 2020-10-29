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
    /// get all existed backups
    func fetchBackups() -> Promise<[KeyDetails]>
    /// backup keys to user inbox
    func backupToInbox(keys: [KeyDetails]) -> Promise<Void>
    /// show activity sheet to save keys as file
    func backupAsFile(keys: [KeyDetails], for viewController: UIViewController)
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

    func backupToInbox(keys: [KeyDetails]) -> Promise<Void> {
        Promise { () -> Void in
            guard let userId = self.userID else {
                throw BackupServiceError.emailNotFound
            }

            let isFullyEncryptedKeys = keys.map { $0.isFullyDecrypted }.contains(false)

            guard isFullyEncryptedKeys else {
                throw BackupServiceError.keyIsNotFullyEncrypted
            }

            let privateKeyContext = keys
                .compactMap { $0 }
                .joinedPrivateKey

            let privateKeyData = privateKeyContext.data().base64EncodedString()

            let filename = "flowcrypt-backup-\(userId.email.userReadableEmail).key"
            let attachments = [SendableMsg.Attachment(name: filename, type: "text/plain", base64: privateKeyData)]
            let message = SendableMsg(
                text: "setup_backup_email".localized,
                to: [userId.toMime],
                cc: [],
                bcc: [],
                from: userId.toMime,
                subject: "Your FlowCrypt Backup",
                replyToMimeMsg: nil,
                atts: attachments
            )
            let backupEmail = try self.core.composeEmail(msg: message, fmt: .plain, pubKeys: nil)
            try await(imap.sendMail(mime: backupEmail.mimeEncoded))
        }
    }

    func backupAsFile(keys: [KeyDetails], for viewController: UIViewController) {
        let file = keys.joinedPrivateKey
        let activityViewController = UIActivityViewController(
            activityItems: [file],
            applicationActivities: nil
        )
        viewController.present(activityViewController, animated: true)
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
