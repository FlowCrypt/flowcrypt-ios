//
//  Gmail+MessageOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST
import GTMSessionFetcher
import Promises

extension GmailService: MessageOperationsProvider {
    func markAsRead(message: Message, folder: String) -> Promise<Void> {
        update(message: message, labelsToAdd: [], labelsToRemove: [.unread])
    }

    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) -> Promise<Void> {
        update(message: message, labelsToAdd: [.trash])
    }

    func delete(message: Message, form folderPath: String?) -> Promise<Void> {
        Promise { resolve, reject in
            guard let identifier = message.identifier.stringId else {
                return reject(GmailServiceError.missedMessageInfo("id"))
            }

            let query = GTLRGmailQuery_UsersMessagesDelete.query(
                withUserId: .me,
                identifier: identifier
            )

            self.gmailService.executeQuery(query) { _, _, error in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                }
                resolve(())
            }
        }
    }

    func archiveMessage(message: Message, folderPath: String) -> Promise<Void> {
        update(
            message: message,
            labelsToRemove: message.labels
                .filter(\.isLabel)
                .map(\.type)
        )
    }

    private func update(message: Message, labelsToAdd: [MessageLabelType] = [], labelsToRemove: [MessageLabelType] = []) -> Promise<Void> {
        Promise { resolve, reject in
            guard let identifier = message.identifier.stringId else {
                return reject(GmailServiceError.missedMessageInfo("id"))
            }
            let request = GTLRGmail_ModifyMessageRequest()
            request.addLabelIds = labelsToAdd.map(\.value)
            request.removeLabelIds = labelsToRemove.map(\.value)
            let query = GTLRGmailQuery_UsersMessagesModify.query(
                withObject: request,
                userId: .me,
                identifier: identifier
            )

            self.gmailService.executeQuery(query) { _, _, error in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                }
                resolve(())
            }
        }
    }
}
