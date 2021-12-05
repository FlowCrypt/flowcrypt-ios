//
//  BackupService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

final class BackupService {
    let backupProvider: BackupProvider
    let core: Core
    let messageSender: MessageGateway

    init(
        backupProvider: BackupProvider,
        core: Core = .shared,
        messageSender: MessageGateway
    ) {
        self.backupProvider = backupProvider
        self.core = core
        self.messageSender = messageSender
    }
}

// MARK: - BackupServiceType
extension BackupService: BackupServiceType {
    func fetchBackupsFromInbox(for userId: UserId) async throws -> [KeyDetails] {
        let backupData = try await self.backupProvider.searchBackups(for: userId.email)
        do {
            let parsed = try await core.parseKeys(armoredOrBinary: backupData)
            let keys = parsed.keyDetails.filter { $0.private != nil }
            return keys
        } catch {
            throw BackupServiceError.parse
        }
    }

    func backupToInbox(keys: [KeyDetails], for userId: UserId) async throws {
        let isFullyEncryptedKeys = keys.map(\.isFullyDecrypted).contains(false)

        guard isFullyEncryptedKeys else {
            throw BackupServiceError.keyIsNotFullyEncrypted
        }

        let privateKeyContext = keys
            .compactMap { $0 }
            .joinedPrivateKey

        let privateKeyData = privateKeyContext.data().base64EncodedString()

        let filename = "flowcrypt-backup-\(userId.email.withoutSpecialCharacters).key"
        let attachments = [SendableMsg.Attachment(name: filename, type: "text/plain", base64: privateKeyData)]
        let message = SendableMsg(
            text: "setup_backup_email".localized,
            to: [userId.toMime],
            cc: [],
            bcc: [],
            from: userId.toMime,
            subject: "Your FlowCrypt Backup",
            replyToMimeMsg: nil,
            atts: attachments,
            pubKeys: nil,
            signingPrv: nil)

        let t = try await core.composeEmail(msg: message, fmt: .plain)
        try await messageSender.sendMail(input: MessageGatewayInput(mime: t.mimeEncoded, threadId: nil),
                                         progressHandler: nil)
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
    var withoutSpecialCharacters: String {
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
