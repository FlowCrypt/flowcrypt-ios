//
//  Gmail+Backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import GoogleAPIClientForREST
import GTMSessionFetcher
import Promises

extension GmailService: BackupProvider {
    func searchBackups(for email: String) -> Promise<Data> {
        Promise { resolve, _ in
            logger.logVerbose("will begin searching for backups")
            let query = backupGenerator.makeBackupQuery(with: GeneralConstants.EmailConstant.recoverAccountSearchSubject)
            let backupMessages = try awaitPromise(searchExpression(using: MessageSearchContext(expression: query)))
            logger.logVerbose("searching done, found \(backupMessages.count) backup messages")
            let uniqueMessages = Set(backupMessages)
            let attachments = uniqueMessages
                .compactMap { message -> [(String, String)]? in
                    logger.logVerbose("processing backup '\(message.subject ?? "-")' with \(message.attachmentIds.count) attachments")
                    guard let identifier = message.identifier.stringId else {
                        logger.logVerbose("skipping this last backup?")
                        return nil
                    }
                    return message.attachmentIds.map { (identifier, $0) }
                }
                .flatMap { $0 }
                .map(findAttachment)
            logger.logVerbose("downloading \(attachments.count) attachments with possible backups in them")
            let data = try awaitPromise(all(attachments)).joined
            logger.logVerbose("downloaded \(attachments.count) attachments that contain \(data.count / 1024)kB of data")
            resolve(data)
        }
    }

    func findAttachment(_ context: (messageId: String, attachmentId: String)) -> Promise<Data> {
        let query = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(
            withUserId: .me,
            messageId: context.messageId,
            identifier: context.attachmentId
        )
        return Promise { resolve, reject in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                    return
                }
                guard let attachmentPart = data as? GTLRGmail_MessagePartBody else {
                    return reject(GmailServiceError.missedMessageInfo("findAttachment data"))
                }

                guard let data = GTLRDecodeBase64(attachmentPart.data) else {
                    return reject(GmailServiceError.messageEncode)
                }

                resolve(data)
            }
        }
    }
}
