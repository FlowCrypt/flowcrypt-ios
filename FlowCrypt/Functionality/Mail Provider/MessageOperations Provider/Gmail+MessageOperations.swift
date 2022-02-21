//
//  Gmail+MessageOperations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail

extension GmailService: MessageOperationsProvider {
    func markAsUnread(message: Message, folder: String) async throws {
        try await update(message: message, labelsToAdd: [.unread])
    }

    func markAsRead(message: Message, folder: String) async throws {
        try await update(message: message, labelsToRemove: [.unread])
    }

    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) async throws {
        try await update(message: message, labelsToAdd: [.trash])
    }

    func delete(message: Message, form folderPath: String?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = message.identifier.stringId else {
                return continuation.resume(throwing: GmailServiceError.missingMessageInfo("id"))
            }

            let query = GTLRGmailQuery_UsersMessagesDelete.query(
                withUserId: .me,
                identifier: identifier
            )

            self.gmailService.executeQuery(query) { _, _, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                return continuation.resume(returning: ())
            }
        }
    }

    func archiveMessage(message: Message, folderPath: String) async throws {
        try await update(
            message: message,
            labelsToRemove: message.labels
                .filter(\.isLabel)
                .map(\.type)
                .filter { $0.isInbox }
        )
    }

    private func update(
        message: Message,
        labelsToAdd: [MessageLabelType] = [],
        labelsToRemove: [MessageLabelType] = []
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = message.identifier.stringId else {
                return continuation.resume(throwing: GmailServiceError.missingMessageInfo("id"))
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
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                return continuation.resume(returning: ())
            }
        }
    }
}
