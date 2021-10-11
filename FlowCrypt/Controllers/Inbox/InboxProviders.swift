//
//  InboxProviders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 11.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import Foundation
import Promises

struct InboxContext {
    let data: [InboxRenderable]
    let pagination: MessagesListPagination
}

class InboxDataProvider {
    func fetchMessages(using context: FetchMessageContext) -> Promise<InboxContext> {
        fatalError("Should be implemented")
    }
}

class InboxMessageThreadsProvider: InboxDataProvider {
    let provider: MessagesThreadProvider

    init(provider: MessagesThreadProvider) {
        self.provider = provider
    }

    override func fetchMessages(using context: FetchMessageContext) -> Promise<InboxContext> {
        Promise<InboxContext> { (resolve, reject) in
            let result = try awaitPromise(self.provider.fetchThreads(using: context))
//            let inboxContext = InboxContext(
//                data: result.data,
//                pagination: result.pagination
//            )
//            resolve(inboxContext)

        }
    }
}

class InboxMessageListProvider: InboxDataProvider {
    let provider: MessagesListProvider

    init(provider: MessagesListProvider = MailProvider.shared.messageListProvider) {
        self.provider = provider
    }

    override func fetchMessages(using context: FetchMessageContext) -> Promise<InboxContext> {
        Promise<InboxContext> { (resolve, reject) in
            let result = try awaitPromise(self.provider.fetchMessages(using: context))
            let inboxContext = InboxContext(
                data: result.messages.map(InboxRenderable.init),
                pagination: result.pagination
            )
            resolve(inboxContext)
        }
    }
}
