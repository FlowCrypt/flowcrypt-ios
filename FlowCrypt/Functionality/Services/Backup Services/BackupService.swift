//
//  BackupService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises
import UIKit

protocol BackupServiceType {
    /// get all existed backups
    func fetchBackups(for userId: UserId) -> Promise<[KeyDetails]>
    /// backup keys to user inbox
    func backupToInbox(keys: [KeyDetails], for userId: UserId) -> Promise<Void>
    /// show activity sheet to save keys as file
    func backupAsFile(keys: [KeyDetails], for viewController: UIViewController)
}

// MARK: - BackupService
final class BackupService {
    let backupProvider: BackupProvider
    let core: Core
    let messageSender: MessageGateway

    init(
        backupProvider: BackupProvider = MailProvider.shared.backupProvider,
        core: Core = .shared,
        messageSender: MessageGateway = MailProvider.shared.messageSender
    ) {
        self.backupProvider = backupProvider
        self.core = core
        self.messageSender = messageSender
    }
}

// MARK: - BackupServiceType
extension BackupService: BackupServiceType {
    func fetchBackups(for userId: UserId) -> Promise<[KeyDetails]> {
        Promise<[KeyDetails]> { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }

            let backupData = try awaitPromise(self.backupProvider.searchBackups(for: userId.email))

            do {
                let parsed = try self.core.parseKeys(armoredOrBinary: backupData)
                let keys = parsed.keyDetails.filter { $0.private != nil }
                resolve(keys)
            } catch {
                reject(BackupServiceError.parse)
            }
        }
    }

    func backupToInbox(keys: [KeyDetails], for userId: UserId) -> Promise<Void> {
        Promise { [weak self] () -> Void in
            guard let self = self else { throw AppErr.nilSelf }

            let isFullyEncryptedKeys = keys.map(\.isFullyDecrypted).contains(false)

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
            try awaitPromise(self.messageSender.sendMail(mime: backupEmail.mimeEncoded))
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
private extension String {
    var userReadableEmail: String {
        self.replacingOccurrences(
            of: "[^a-z0-9]",
            with: "",
            options: .regularExpression
        )
    }
}

private extension UserId {
    var toMime: String {
        "\(name) <\(email)>"
    }
}
