//
//  MessageActionsHelper.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 19.12.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageActionsHelper {
    private let threadOperationsApiClient: MessagesThreadOperationsApiClient

    init(threadOperationsApiClient: MessagesThreadOperationsApiClient) {
        self.threadOperationsApiClient = threadOperationsApiClient
    }

    func perform(action: MessageAction, with inboxItem: InboxItem) async throws {
        switch action {
        case .archive:
            try await threadOperationsApiClient.archive(
                messagesIds: inboxItem.messages.map(\.identifier),
                in: inboxItem.folderPath
            )
        case .markAsUnread:
            Task { // Run mark as unread operation in another thread
                try await threadOperationsApiClient.markThreadAsUnread(
                    id: inboxItem.threadId,
                    folder: inboxItem.folderPath
                )
            }
        case .markAsRead:
            break
        case .moveToTrash:
            try await threadOperationsApiClient.moveThreadToTrash(
                id: inboxItem.threadId,
                labels: inboxItem.labels
            )
        case .moveToInbox:
            try await threadOperationsApiClient.moveThreadToInbox(id: inboxItem.threadId)
        case .permanentlyDelete:
            try await threadOperationsApiClient.delete(id: inboxItem.threadId)
        }
    }
}
