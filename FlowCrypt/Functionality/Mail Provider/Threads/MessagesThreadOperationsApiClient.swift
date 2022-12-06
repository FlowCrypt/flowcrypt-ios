//
//  MessagesThreadOperationsApiClient.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

protocol MessagesThreadOperationsApiClient {
    func delete(id: String?) async throws
    func moveThreadToTrash(id: String?, labels: Set<MessageLabel>) async throws
    func moveThreadToInbox(id: String?) async throws
    func markThreadAsUnread(id: String?, folder: String) async throws
    func mark(messagesIds: [Identifier], asRead: Bool, in folder: String) async throws
    func archive(messagesIds: [Identifier], in folder: String) async throws
}

extension GmailService: MessagesThreadOperationsApiClient {
    func delete(id: String?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let id else {
                return continuation.resume(throwing: GmailApiError.missingMessageInfo("id"))
            }

            let query = GTLRGmailQuery_UsersThreadsDelete.query(
                withUserId: .me,
                identifier: id
            )

            self.gmailService.executeQuery(query) { _, _, error in
                if let error {
                    return continuation.resume(throwing: GmailApiError.providerError(error))
                }
                return continuation.resume()
            }
        }
    }

    func moveThreadToTrash(id: String?, labels: Set<MessageLabel>) async throws {
        try await update(id: id, labelsToAdd: [.trash])
    }

    func moveThreadToInbox(id: String?) async throws {
        try await update(id: id, labelsToAdd: [.inbox], labelsToRemove: [.trash])
    }

    func markThreadAsUnread(id: String?, folder: String) async throws {
        try await update(id: id, labelsToAdd: [.unread])
    }

    func mark(messagesIds: [Identifier], asRead: Bool, in folder: String) async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for id in messagesIds {
                taskGroup.addTask {
                    asRead
                        ? try await self.markAsRead(id: id, folder: folder)
                        : try await self.markAsUnread(id: id, folder: folder)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func archive(messagesIds: [Identifier], in folder: String) async throws {
        // manually updated each message rather than using update(thread:...) method
        // https://github.com/FlowCrypt/flowcrypt-ios/pull/1769#discussion_r932964129
        try await batchUpdate(
            messagesIds: messagesIds,
            labelsToRemove: [.inbox]
        )
    }

    private func update(
        id: String?,
        labelsToAdd: [MessageLabel] = [],
        labelsToRemove: [MessageLabel] = []
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let id else {
                return continuation.resume(throwing: GmailApiError.missingMessageInfo("id"))
            }

            let request = GTLRGmail_ModifyThreadRequest()
            request.addLabelIds = labelsToAdd.map(\.value)
            request.removeLabelIds = labelsToRemove.map(\.value)

            let query = GTLRGmailQuery_UsersThreadsModify.query(
                withObject: request,
                userId: .me,
                identifier: id
            )

            self.gmailService.executeQuery(query) { _, _, error in
                if let error {
                    return continuation.resume(throwing: GmailApiError.providerError(error))
                }
                return continuation.resume()
            }
        }
    }
}
