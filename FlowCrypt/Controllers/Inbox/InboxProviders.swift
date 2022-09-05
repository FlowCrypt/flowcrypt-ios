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
    func fetchInboxItems(using context: FetchMessageContext, userEmail: String) async throws -> InboxContext
}

// used when displaying conversations (threads) in inbox (Gmail API default)
class InboxMessageThreadsProvider: InboxDataProvider {
    let provider: MessagesThreadProvider

    init(provider: MessagesThreadProvider) {
        self.provider = provider
    }

    func fetchInboxItems(using context: FetchMessageContext, userEmail: String) async throws -> InboxContext {
        let result = try await provider.fetchThreads(using: context)

        let inboxData = result.threads.map {
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

    func fetchInboxItems(using context: FetchMessageContext, userEmail: String) async throws -> InboxContext {
        let result = try await provider.fetchMessages(using: context)

        let inboxData = result.messages.map(InboxRenderable.init)

        let inboxContext = InboxContext(
            data: inboxData,
            pagination: result.pagination
        )

        return inboxContext
    }
}
