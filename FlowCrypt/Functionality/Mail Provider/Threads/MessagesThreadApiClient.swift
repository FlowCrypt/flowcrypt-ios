//
//  MessagesThreadApiClient.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST_Gmail

protocol MessagesThreadApiClient {
    func fetchThread(identifier: String, path: String) async throws -> MessageThread
    func fetchThreads(using context: FetchMessageContext) async throws -> MessageThreadContext
}

extension GmailService: MessagesThreadApiClient {
    func fetchThreads(using context: FetchMessageContext) async throws -> MessageThreadContext {
        let threadsList = try await getThreadsList(using: context)
        let identifiers = threadsList.threads?.compactMap(\.identifier) ?? []

        return try await withThrowingTaskGroup(of: MessageThread.self) { taskGroup in
            var messageThreadsById: [String: MessageThread] = [:]
            for identifier in identifiers {
                taskGroup.addTask {
                    try await self.fetchThread(identifier: identifier, path: context.folderPath ?? "")
                }
            }
            for try await result in taskGroup {
                if let id = result.identifier {
                    messageThreadsById[id] = result
                }
            }
            let messageThreads = identifiers.compactMap { messageThreadsById[$0] }
            return MessageThreadContext(
                threads: messageThreads,
                pagination: .byNextPage(token: threadsList.nextPageToken)
            )
        }
    }

    private func getThreadsList(using context: FetchMessageContext) async throws -> GTLRGmail_ListThreadsResponse {
        let query = try makeQuery(using: context)
        return try await Task.retrying {
            try await withCheckedThrowingContinuation { continuation in
                self.gmailService.executeQuery(query) { _, data, error in
                    if let error {
                        let gmailError = GmailApiError.convert(from: error as NSError)
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

    func fetchThread(identifier: String, path: String) async throws -> MessageThread {
        let query = GTLRGmailQuery_UsersThreadsGet.query(withUserId: .me, identifier: identifier)
        query.format = kGTLRGmailFormatFull
        var thread = try await fetchThread(with: query, in: path)
        for index in thread.messages.indices {
            try await MessageHelper.parseAttachmentTypes(message: &thread.messages[index])
        }
        return thread
    }

    private func fetchThread(with query: GTLRGmailQuery_UsersThreadsGet, in path: String) async throws -> MessageThread {
        return try await Task.retrying {
            try await withCheckedThrowingContinuation { continuation in
                self.gmailService.executeQuery(query) { _, data, error in
                    if let error {
                        return continuation.resume(throwing: GmailApiError.providerError(error))
                    }

                    guard let gmailThread = data as? GTLRGmail_Thread else {
                        return continuation.resume(throwing: AppErr.cast("GTLRGmail_Thread"))
                    }

                    var messages = gmailThread.messages?.compactMap { try? Message(gmailMessage: $0) } ?? []

                    // For trash folder: Only display deleted messages in thread
                    // For othr folders: Exclude deleted messages in thread
                    // https://github.com/FlowCrypt/flowcrypt-ios/issues/2292
                    let isTrashFolder = path == GeneralConstants.Gmail.trashLabelPath
                    messages = messages.filter { $0.labels.contains(.trash) == isTrashFolder }

                    let thread = MessageThread(
                        identifier: gmailThread.identifier,
                        snippet: gmailThread.snippet,
                        messages: messages
                    )

                    return continuation.resume(returning: thread)
                }
            }
        }.value
    }

    private func makeQuery(using context: FetchMessageContext) throws -> GTLRGmailQuery_UsersThreadsList {
        let query = GTLRGmailQuery_UsersThreadsList.query(withUserId: .me)

        if let pagination = context.pagination {
            guard case let .byNextPage(token) = pagination else {
                throw GmailApiError.paginationError(pagination)
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
