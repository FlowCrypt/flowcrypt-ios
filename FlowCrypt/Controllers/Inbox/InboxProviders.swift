//
//  InboxProviders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 11.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct InboxContext {
    let data: [InboxRenderable]
    let pagination: MessagesListPagination
}

protocol InboxDataProvider {
    func fetchInboxItem(identifier: Identifier, path: String) async throws -> InboxRenderable?
    func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext
}

// used when displaying conversations (threads) in inbox (Gmail API default)
class InboxMessageThreadsProvider: InboxDataProvider {
    let provider: MessagesThreadProvider

    init(provider: MessagesThreadProvider) {
        self.provider = provider
    }

    func fetchInboxItem(identifier: Identifier, path: String) async throws -> InboxRenderable? {
        guard let id = identifier.stringId else { return nil }
        let thread = try await provider.fetchThread(identifier: id, path: path)
        return InboxRenderable(thread: thread, folderPath: path)
    }

    func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext {
        let result = try await provider.fetchThreads(using: context)

        let inboxData = result.threads
            .sorted(by: {
                $0.latestMessageDate(with: context.folderPath) > $1.latestMessageDate(with: context.folderPath)
            })
            .map {
                InboxRenderable(
                    thread: $0,
                    folderPath: context.folderPath
                )
            }

        let inboxContext = InboxContext(
            data: inboxData,
            pagination: result.pagination
        )

        return inboxContext
    }
}

// used when displaying individual messages in inbox (IMAP)
class InboxMessageListProvider: InboxDataProvider {
    let provider: MessagesListProvider

    init(provider: MessagesListProvider) {
        self.provider = provider
    }

    func fetchInboxItem(identifier: Identifier, path: String) async throws -> InboxRenderable? {
        let message = try await provider.fetchMessage(id: identifier, folder: path)
        return InboxRenderable(message: message)
    }

    func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext {
        let result = try await provider.fetchMessages(using: context)

        let inboxData = result.messages.map(InboxRenderable.init)

        let inboxContext = InboxContext(
            data: inboxData,
            pagination: result.pagination
        )

        return inboxContext
    }
}
