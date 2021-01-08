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
        return Promise { (resolve, _) in
            let backupSearchExpressions = GeneralConstants.EmailConstant
                .recoverAccountSearchSubject
                .map { searchExpression(using: MessageSearchContext(expression: $0)) }

            let backupMessages = try await(all(backupSearchExpressions))
                .flatMap { $0 }
            let uniqueMessages = Set(backupMessages)
            let attachments = uniqueMessages
                .compactMap { (message) -> [(String, String)]? in
                    guard let id = message.identifier.stringId else {
                        return nil
                    }
                    return message.attachmentIds.map { (id, $0) }
                }
                .flatMap { $0 }
                .map(findAttachment)

            // TODO: - TOM 1
            // Here I'm getting the correct number of attachments with backups (17 for cryptup.tester@gmail.com account)

            let data = try await(all(attachments)).joined
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
