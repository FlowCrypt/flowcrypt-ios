//
//  Gmail+MessageOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: MessageOperationsProvider {
    func markAsRead(message: Message, folder: String) -> Promise<Void> {
        return Promise { (resolve, reject) in
            guard let id = message.identifier.stringId else {
                return reject(GmailServiceError.missedMessageInfo("id"))
            }
            let request = GTLRGmail_ModifyMessageRequest()
            request.removeLabelIds = [MessageLabelType.unread.value]
            let query = GTLRGmailQuery_UsersMessagesModify.query(
                withObject: request,
                userId: .me,
                identifier: id
            )

            self.gmailService.executeQuery(query) { (_, _, error) in
                if let error = error {
                    reject(AppErr.providerError(error))
                }
                resolve(())
            }
        }
    }

    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) -> Promise<Void> {
        return Promise { (resolve, reject) in
            guard let id = message.identifier.stringId else {
                return reject(GmailServiceError.missedMessageInfo("id"))
            }
            let request = GTLRGmail_ModifyMessageRequest()
            request.addLabelIds = [MessageLabelType.trash.value]
            let query = GTLRGmailQuery_UsersMessagesModify.query(
                withObject: request,
                userId: .me,
                identifier: id
            )

            self.gmailService.executeQuery(query) { (_, _, error) in
                if let error = error {
                    reject(AppErr.providerError(error))
                }
                resolve(())
            }
        }
    }
}
