//
//  MessagesThreadProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST_Gmail

protocol MessagesThreadProvider {
    func fetchThreads(using context: FetchMessageContext) async throws -> MessageThreadContext
}

extension GmailService: MessagesThreadProvider {
    func fetchThreads(using context: FetchMessageContext) async throws -> MessageThreadContext {
        let threadsList = try await getThreadsList(using: context)
        let requests = threadsList.threads?
            .compactMap { (thread) -> (String, String?)? in
                guard let id = thread.identifier else {
                    return nil
                }
                return (id, thread.snippet)
            }
        ?? []
        return try await withThrowingTaskGroup(of: MessageThread.self) { (taskGroup) in
            var messageThreadsById: [String: MessageThread] = [:]
            for request in requests {
                taskGroup.addTask {
                    try await self.getThread(with: request.0, snippet: request.1, path: context.folderPath ?? "")
                }
            }
            for try await result in taskGroup {
                if let id = result.identifier {
                    messageThreadsById[id] = result
                }
            }
            let messageThreads = requests.compactMap { messageThreadsById[$0.0] }
            return MessageThreadContext(
                threads: messageThreads,
                pagination: .byNextPage(token: threadsList.nextPageToken)
            )
        }
    }

    private func getThreadsList(using context: FetchMessageContext) async throws -> GTLRGmail_ListThreadsResponse {
        let query = try makeQuery(using: context)
        return try await Task.retrying {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRGmail_ListThreadsResponse, Error>) in
                self.gmailService.executeQuery(query) { _, data, error in
                    if let error = error {
                        let gmailError = GmailServiceError.convert(from: error as NSError)
                        return continuation.resume(throwing: gmailError)
                    }

                    guard let threadsResponse = data as? GTLRGmail_ListThreadsResponse else {
                        return continuation.resume(throwing: AppErr.cast("GTLRGmail_ListThreadsResponse"))
                    }
                    return continuation.resume(returning: threadsResponse)
                }
            }
        }.value
    }

    private func getThread(with identifier: String, snippet: String?, path: String) async throws -> MessageThread {
        return try await Task.retrying {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MessageThread, Error>) in
                self.gmailService.executeQuery(
                    GTLRGmailQuery_UsersThreadsGet.query(withUserId: .me, identifier: identifier)
                ) { (_, data, error) in
                    if let error = error {
                        return continuation.resume(throwing: GmailServiceError.providerError(error))
                    }

                    guard let thread = data as? GTLRGmail_Thread else {
                        return continuation.resume(throwing: AppErr.cast("GTLRGmail_Thread"))
                    }

                    guard let threadMsg = thread.messages else {
                        let empty = MessageThread(
                            identifier: identifier,
                            snippet: snippet,
                            path: path,
                            messages: []
                        )
                        return continuation.resume(returning: empty)
                    }

                    let messages = threadMsg.compactMap { try? Message($0) }

                    let result = MessageThread(
                        identifier: thread.identifier,
                        snippet: snippet,
                        path: path,
                        messages: messages
                    )
                    return continuation.resume(returning: result)
                }
            }
        }.value
    }

    private func makeQuery(using context: FetchMessageContext) throws -> GTLRGmailQuery_UsersThreadsList {
        let query = GTLRGmailQuery_UsersThreadsList.query(withUserId: .me)

        if let pagination = context.pagination {
            guard case let .byNextPage(token) = pagination else {
                throw GmailServiceError.paginationError(pagination)
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
}
