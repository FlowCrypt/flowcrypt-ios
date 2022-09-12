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
    func markAsUnread(id: Identifier, folder: String) async throws {
        try await updateMessage(id: id, labelsToAdd: [.unread])
    }

    func markAsRead(id: Identifier, folder: String) async throws {
        try await updateMessage(id: id, labelsToRemove: [.unread])
    }

    func moveMessageToInbox(id: Identifier, folderPath: String) async throws {
        try await updateMessage(id: id, labelsToAdd: [.inbox])
    }

    func moveMessageToTrash(id: Identifier, trashPath: String?, from folder: String) async throws {
        try await updateMessage(id: id, labelsToAdd: [.trash])
    }

    func deleteMessage(id: Identifier, from folderPath: String?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = id.stringId else {
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
                return continuation.resume()
            }
        }
    }

    func emptyFolder(path: String) async throws {
        let messageIdentifiers = try await fetchAllMessageIdentifiers(for: path)
        try await batchDeleteMessages(identifiers: messageIdentifiers, from: path)
    }

    private func fetchAllMessageIdentifiers(
        for path: String,
        token: String? = nil,
        result: [String] = []
    ) async throws -> [String] {
        let context = FetchMessageContext(folderPath: path, count: 500, pagination: .byNextPage(token: token))
        let list = try await fetchMessagesList(using: context)

        let newResult = (list.messages?.compactMap(\.identifier) ?? []) + result

        if let nextPageToken = list.nextPageToken {
            return try await fetchAllMessageIdentifiers(for: path, token: nextPageToken, result: newResult)
        } else {
            return newResult
        }
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
                return continuation.resume()
            }
        }
    }

    func archiveMessage(id: Identifier, folderPath: String) async throws {
        try await updateMessage(
            id: id,
            labelsToRemove: [.inbox]
        )
    }

    func archiveBatchMessages(messages: [Message]) async throws {
        try await batchUpdate(
            messages: messages,
            labelsToRemove: [.inbox]
        )
    }

    private func batchUpdate(
        messages: [Message],
        labelsToAdd: [MessageLabel] = [],
        labelsToRemove: [MessageLabel] = []
    ) async throws {
        let request = GTLRGmail_BatchModifyMessagesRequest()
        request.ids = messages.compactMap { $0.identifier.stringId }
        request.addLabelIds = labelsToAdd.map(\.value)
        request.removeLabelIds = labelsToRemove.map(\.value)
        let query = GTLRGmailQuery_UsersMessagesBatchModify.query(
            withObject: request,
            userId: .me
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.gmailService.executeQuery(query) { _, _, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                return continuation.resume()
            }
        }
    }

    private func updateMessage(
        id: Identifier,
        labelsToAdd: [MessageLabel] = [],
        labelsToRemove: [MessageLabel] = []
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = id.stringId else {
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
                return continuation.resume()
            }
        }
    }
}
