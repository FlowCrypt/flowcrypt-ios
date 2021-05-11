//
//  Gmail+Backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: BackupProvider {
    func searchBackups(for email: String) -> Promise<Data> {
        Logger.logVerbose("[GmailService] will begin searching for backups")
        return Promise { (resolve, _) in
            let backupSearchExpressions = GeneralConstants.EmailConstant
                .recoverAccountSearchSubject
                .map { searchExpression(using: MessageSearchContext(expression: $0)) }

            Logger.logVerbose("[GmailService] searching with \(backupSearchExpressions.count) search expressions")
            let backupMessages = try awaitPromise(all(backupSearchExpressions))
                .flatMap { $0 }
            Logger.logVerbose("[GmailService] searching done, found \(backupMessages.count) backup messages")
            let uniqueMessages = Set(backupMessages)
            let attachments = uniqueMessages
                .compactMap { (message) -> [(String, String)]? in
                    Logger.logVerbose("[GmailService] processing backup '\(message.subject ?? "-")' with \(message.attachmentIds.count) attachments")
                    guard let identifier = message.identifier.stringId else {
                        Logger.logVerbose("[GmailService] skipping this last backup?")
                        return nil
                    }
                    return message.attachmentIds.map { (identifier, $0) }
                }
                .flatMap { $0 }
                .map(findAttachment)
            Logger.logVerbose("[GmailService] downloading \(attachments.count) attachments with possible backups in them")
            let data = try awaitPromise(all(attachments)).joined
            Logger.logVerbose("[GmailService] downloaded \(attachments.count) attachments that contain \(data.count / 1024)kB of data")
            resolve(data)
        }
    }

    func findAttachment(_ context: (messageId: String, attachmentId: String)) -> Promise<Data> {
        let query = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(
            withUserId: .me,
            messageId: context.messageId,
            identifier: context.attachmentId
        )
        return Promise { (resolve, reject) in
            self.gmailService.executeQuery(query) { (_, data, error) in
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
