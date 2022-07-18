//
//  MessagesThreadOperationsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail

protocol MessagesThreadOperationsProvider {
    func mark(thread: MessageThread, asRead: Bool, in folder: String) async throws
    func delete(thread: MessageThread) async throws
    func moveThreadToTrash(thread: MessageThread) async throws
    func moveThreadToInbox(thread: MessageThread) async throws
    func markThreadAsUnread(thread: MessageThread, folder: String) async throws
    func markThreadAsRead(thread: MessageThread, folder: String) async throws
    func archive(thread: MessageThread, in folder: String) async throws
}

extension GmailService: MessagesThreadOperationsProvider {
    func delete(thread: MessageThread) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = thread.identifier else {
                return continuation.resume(throwing: GmailServiceError.missingMessageInfo("id"))
            }

            let query = GTLRGmailQuery_UsersThreadsDelete.query(
                withUserId: .me,
                identifier: identifier
            )

            self.gmailService.executeQuery(query) { _, _, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                continuation.resume(returning: ())
            }
        }
    }

    func moveThreadToTrash(thread: MessageThread) async throws {
        try await update(thread: thread, labelsToAdd: [.trash], labelsToRemove: [.inbox, .sent])
    }

    func moveThreadToInbox(thread: MessageThread) async throws {
        try await update(thread: thread, labelsToAdd: [.inbox], labelsToRemove: [.trash])
    }

    func markThreadAsUnread(thread: MessageThread, folder: String) async throws {
        try await update(thread: thread, labelsToAdd: [.unread])
    }

    func markThreadAsRead(thread: MessageThread, folder: String) async throws {
        try await update(thread: thread, labelsToRemove: [.unread])
    }

    func mark(thread: MessageThread, asRead: Bool, in folder: String) async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for message in thread.messages {
                taskGroup.addTask {
                    asRead
                    ? try await self.markAsRead(message: message, folder: folder)
                    : try await self.markAsUnread(message: message, folder: folder)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func archive(thread: MessageThread, in folder: String) async throws {
        try await update(thread: thread, labelsToRemove: [.inbox])
    }

    private func update(
        thread: MessageThread,
        labelsToAdd: [MessageLabel] = [],
        labelsToRemove: [MessageLabel] = []
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = thread.identifier else {
                return continuation.resume(throwing: GmailServiceError.missingMessageInfo("id"))
            }

            let request = GTLRGmail_ModifyThreadRequest()
            request.addLabelIds = labelsToAdd.map(\.value)
            request.removeLabelIds = labelsToRemove.map(\.value)

            let query = GTLRGmailQuery_UsersThreadsModify.query(
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
