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
    func delete(thread: MessageThread) async throws
    func moveThreadToTrash(thread: MessageThread) async throws
    func markThreadAsUnread(thread: MessageThread, folder: String) async throws
    func markThreadAsRead(thread: MessageThread, folder: String) async throws

    // func archive(thread: MessageThread) async throws
}

extension GmailService: MessagesThreadOperationsProvider {
    func delete(thread: MessageThread) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = thread.identifier else {
                return continuation.resume(throwing: GmailServiceError.missedMessageInfo("id"))
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
        try await update(thread: thread, labelsToAdd: [.trash])
    }

    func markThreadAsUnread(thread: MessageThread, folder: String) async throws {
        try await update(thread: thread, labelsToAdd: [.unread])
    }

    func markThreadAsRead(thread: MessageThread, folder: String) async throws {
        try await update(thread: thread, labelsToRemove: [.unread])
    }

    // TODO: - ANTON - archive
//    func archive(thread: MessageThread) async throws {
//        try await update(
//            thread: thread,
//            labelsToRemove: thread.labels
//                .filter(\.isLabel)
//                .map(\.type)
//        )
//    }

    private func update(
        thread: MessageThread,
        labelsToAdd: [MessageLabelType] = [],
        labelsToRemove: [MessageLabelType] = []
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let identifier = thread.identifier else {
                return continuation.resume(throwing: GmailServiceError.missedMessageInfo("id"))
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
                    continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                continuation.resume(returning: ())
            }
        }
    }
}
