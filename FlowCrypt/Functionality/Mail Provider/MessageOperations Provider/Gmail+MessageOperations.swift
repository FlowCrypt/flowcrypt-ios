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

    func moveMessageToInbox(message: Message, folderPath: String) async throws {
        try await update(message: message, labelsToAdd: [.inbox])
    }

    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) async throws {
        try await update(message: message, labelsToAdd: [.trash])
    }

    func delete(message: Message, from folderPath: String?) async throws {
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

    func emptyFolder(path: String) async throws {
        let messageIdentifiers = try await fetchAllMessageIdentifers(for: path)
        try await batchDeleteMessages(identifiers: messageIdentifiers, from: path)
    }

    private func fetchAllMessageIdentifers(for path: String, token: String? = nil, result: [String] = []) async throws -> [String] {
        let context = FetchMessageContext(folderPath: path, count: 500, pagination: .byNextPage(token: token))
        let list = try await fetchMessagesList(using: context)
        var newResult = (list.messages?.compactMap(\.identifier) ?? []) + result
        if let nextPageToken = list.nextPageToken {
            newResult = try await fetchAllMessageIdentifers(for: path, token: nextPageToken, result: newResult)
        }
        return newResult
    }

    func batchDeleteMessages(identifiers: [String], from folderPath: String?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let request = GTLRGmail_BatchDeleteMessagesRequest()
            request.ids = identifiers
            let query = GTLRGmailQuery_UsersMessagesBatchDelete.query(withObject: request, userId: .me)

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
            labelsToRemove: [.inbox]
        )
    }

    private func update(
        message: Message,
        labelsToAdd: [MessageLabel] = [],
        labelsToRemove: [MessageLabel] = []
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
