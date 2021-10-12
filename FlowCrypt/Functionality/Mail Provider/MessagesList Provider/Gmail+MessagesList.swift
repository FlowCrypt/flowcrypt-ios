//
//  Gmail_MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST_Gmail
import Promises
import UIKit

struct MessageThread {
    let snippet: String?
    let messages: [Message]
}

struct MessageThreadContext {
    let threads: [MessageThread]
    let pagination: MessagesListPagination
}

protocol MessagesThreadProvider {
    func fetchThreads(using context: FetchMessageContext) -> Promise<MessageThreadContext>
}

extension GmailService: MessagesThreadProvider {
    func fetchThreads(using context: FetchMessageContext) -> Promise<MessageThreadContext> {
        Promise<MessageThreadContext> { (resolve, _) in
            let threadsList = try awaitPromise(getThreadsList(using: context))
            let threadsRequests = threadsList.threads?
                .compactMap {
                    if let id = $0.identifier {
                        return (id, $0.snippet)
                    }
                    return nil
                }
                .map(getThread)
            ?? []

            all(threadsRequests)
                .then { result in
                    let messageThreadContext = MessageThreadContext(
                        threads: result,
                        pagination: .byNextPage(token: threadsList.nextPageToken)
                    )
                    resolve(messageThreadContext)
                }
        }
    }

    private func getThreadsList(using context: FetchMessageContext) -> Promise<GTLRGmail_ListThreadsResponse> {
        Promise<GTLRGmail_ListThreadsResponse> { (resolve, reject) in
            let query = makeQuery(using: context)

            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                    return
                }

                guard let threadsResponse = data as? GTLRGmail_ListThreadsResponse else {
                    return reject(AppErr.cast("GTLRGmail_ListThreadsResponse"))
                }

                resolve(threadsResponse)
            }
        }
    }

    private func makeQuery(using context: FetchMessageContext) -> GTLRGmailQuery_UsersThreadsList {
        let query = GTLRGmailQuery_UsersThreadsList.query(withUserId: .me)

        if let pagination = context.pagination {
            guard case let .byNextPage(token) = pagination else {
                fatalError("Pagination \(String(describing: context.pagination)) is not supported for this provider")
            }
            query.pageToken = token
        }

        if let folderPath = context.folderPath, folderPath.isNotEmpty {
            query.labelIds = [folderPath]
        }
        if let count = context.count {
            query.maxResults = UInt(count)
        }
        if let searchQuery = context.searchQuery {
            query.q = searchQuery
        }

        return query
    }

    private func getThread(with identifier: String, snippet: String?) -> Promise<MessageThread> {
        Promise<MessageThread> { (resolve, reject) in
            let query = GTLRGmailQuery_UsersThreadsGet.query(withUserId: .me, identifier: identifier)
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return reject(GmailServiceError.providerError(error))
                }

                guard let thread = data as? GTLRGmail_Thread else {
                    return reject(AppErr.cast("GTLRGmail_Thread"))
                }

                do {
                    let messages = try (thread.messages ?? []).compactMap(Message.init)
                    let thread = MessageThread(
                        snippet: snippet,
                        messages: messages
                    )
                    resolve(thread)
                } catch {
                    reject(error)
                }
            }
        }
    }
}

private extension Message {
    init(_ message: GTLRGmail_Message) throws {
        guard let payload = message.payload else {
            throw GmailServiceError.missedMessagePayload
        }

        guard let messageHeaders = payload.headers else {
            throw GmailServiceError.missedMessageInfo("headers")
        }

        guard let internalDate = message.internalDate as? Double else {
            throw GmailServiceError.missedMessageInfo("date")
        }

        guard let identifier = message.identifier else {
            throw GmailServiceError.missedMessageInfo("id")
        }

        let attachmentsIds = payload.parts?.compactMap { $0.body?.attachmentId } ?? []
        let labelTypes: [MessageLabelType] = message.labelIds?.map(MessageLabelType.init) ?? []
        let labels = labelTypes.map(MessageLabel.init)

        var sender: String?
        var subject: String?

        messageHeaders.compactMap { $0 }.forEach {
            guard let name = $0.name?.lowercased() else { return }
            let value = $0.value
            switch name {
            case .from: sender = value
            case .subject: subject = value
            default: break
            }
        }

        // TODO: - Tom 3
        // Gmail returns sender string as "Google security <googleaccount-noreply@gmail.com>"
        // slice it to previous format, like "googleaccount-noreply@gmail.com"
        sender = sender?.slice(from: "<", to: ">") ?? sender

        self.init(
            identifier: Identifier(stringId: identifier),
            // Should be divided by 1000, because Date(timeIntervalSince1970:) expects seconds
            // but GTLRGmail_Message.internalDate is in miliseconds
            date: Date(timeIntervalSince1970: internalDate / 1000),
            sender: sender,
            subject: subject,
            size: message.sizeEstimate.flatMap(Int.init),
            labels: labels,
            attachmentIds: attachmentsIds,
            threadId: message.threadId
        )
    }
}
