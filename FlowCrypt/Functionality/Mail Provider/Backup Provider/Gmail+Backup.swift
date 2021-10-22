//
//  Gmail+Backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail
import Promises

extension GmailService: BackupProvider {
    func searchBackups(for email: String) async throws -> Data {
        do {
            logger.logVerbose("will begin searching for backups")
            let query = try backupSearchQueryProvider.makeBackupQuery(for: email)
            let backupMessages = try await searchExpression(using: MessageSearchContext(expression: query))
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
            return data
        } catch {
            if error is GmailServiceError {
                throw error
            }
            throw GmailServiceError.missedBackupQuery(error)
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
