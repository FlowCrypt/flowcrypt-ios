//
//  InboxProviders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 11.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct InboxContext {
    let data: [InboxItem]
    let pagination: MessagesListPagination
}

protocol InboxDataApiClient {
    func fetchInboxItem(identifier: MessageIdentifier, path: String) async throws -> InboxItem?
    func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext
}

// used when displaying conversations (threads) in inbox (Gmail API default)
class InboxMessageThreadsProvider: InboxDataApiClient {
    let apiClient: MessagesThreadApiClient

    init(apiClient: MessagesThreadApiClient) {
        self.apiClient = apiClient
    }

    func fetchInboxItem(identifier: MessageIdentifier, path: String) async throws -> InboxItem? {
        guard let id = identifier.threadId?.stringId else { return nil }
        let thread = try await apiClient.fetchThread(identifier: id, path: path)
        return InboxItem(thread: thread, folderPath: path, identifier: identifier)
    }

    func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext {
        let result = try await apiClient.fetchThreads(using: context)

        let inboxData = result.threads
            .map { InboxItem(thread: $0, folderPath: context.folderPath) }
            .sorted {
                $0.latestMessageDate(with: context.folderPath) > $1.latestMessageDate(with: context.folderPath)
            }

        let inboxContext = InboxContext(
            data: inboxData,
            pagination: result.pagination
        )

        return inboxContext
    }
}

// used when displaying individual messages in inbox (IMAP)
class InboxMessageListProvider: InboxDataApiClient {
    let apiClient: MessagesListApiClient

    init(apiClient: MessagesListApiClient) {
        self.apiClient = apiClient
    }

    func fetchInboxItem(identifier: MessageIdentifier, path: String) async throws -> InboxItem? {
        guard let id = identifier.messageId else { return nil }
        let message = try await apiClient.fetchMessage(id: id, folder: path)
        return InboxItem(message: message)
    }

    func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext {
        let result = try await apiClient.fetchMessages(using: context)

        let inboxData = result.messages.map(InboxItem.init)

        let inboxContext = InboxContext(
            data: inboxData,
            pagination: result.pagination
        )

        return inboxContext
    }
}
