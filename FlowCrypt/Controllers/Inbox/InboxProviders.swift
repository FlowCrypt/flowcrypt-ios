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

class InboxDataProvider {
    func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext {
        fatalError("Should be implemented")
    }
}

// used when displaying conversations (threads) in inbox (Gmail API default)
class InboxMessageThreadsProvider: InboxDataProvider {
    let provider: MessagesThreadProvider

    init(provider: MessagesThreadProvider) {
        self.provider = provider
    }

    override func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext {
        let result = try await provider.fetchThreads(using: context)
        let inboxData = result.threads.map(InboxRenderable.init)
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

    init(provider: MessagesListProvider = MailProvider.shared.messageListProvider) {
        self.provider = provider
    }

    override func fetchInboxItems(using context: FetchMessageContext) async throws -> InboxContext {
        let result = try await provider.fetchMessages(using: context)
        let inboxData = result.messages.map(InboxRenderable.init)
        let inboxContext = InboxContext(
            data: inboxData,
            pagination: result.pagination
        )
        return inboxContext
    }
}
