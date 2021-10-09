//
//  BackupService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import Promises
import UIKit

final class BackupService {
    let backupProvider: BackupProvider
    let core: Core
    let messageSender: MessageGateway
    private var cancellable = Set<AnyCancellable>()

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
    func fetchBackupsFromInbox(for userId: UserId) -> Promise<[KeyDetails]> {
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
        Promise { [weak self] resolve, reject -> Void in
            guard let self = self else { throw AppErr.nilSelf }

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
                pubKeys: nil)

            self.core.composeEmail(msg: message, fmt: .plain)
                .map({ MessageGatewayInput(mime: $0.mimeEncoded, threadId: nil) })
                .flatMap(self.messageSender.sendMail)
                .sink(
                    receiveCompletion: { result in
                        switch result {
                        case .failure(let error):
                            reject(error)
                        case .finished:
                            break
                        }
                    },
                    receiveValue: {
                        resolve(())
                    }
                )
                .store(in: &self.cancellable)
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
