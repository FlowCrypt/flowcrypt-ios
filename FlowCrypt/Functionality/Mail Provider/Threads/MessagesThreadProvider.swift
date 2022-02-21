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
        let threadsList = (try await getThreadsList(using: context))
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
        let query = makeQuery(using: context)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRGmail_ListThreadsResponse, Error>) in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }

                guard let threadsResponse = data as? GTLRGmail_ListThreadsResponse else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_ListThreadsResponse"))
                }
                return continuation.resume(returning: threadsResponse)
            }
        }
    }

    private func getThread(with identifier: String, snippet: String?, path: String) async throws -> MessageThread {
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

                let messages = threadMsg.compactMap { try? Message($0, draftIdentifier: nil) }

                let result = MessageThread(
                    identifier: thread.identifier,
                    snippet: snippet,
                    path: path,
                    messages: messages
                )
                return continuation.resume(returning: result)
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
}

extension Message {
    init(
        _ message: GTLRGmail_Message,
        draftIdentifier: String? = nil
    ) throws {
        guard let payload = message.payload else {
            throw GmailServiceError.missingMessagePayload
        }

        guard let messageHeaders = payload.headers else {
            throw GmailServiceError.missingMessageInfo("headers")
        }

        guard let internalDate = message.internalDate as? Double else {
            throw GmailServiceError.missingMessageInfo("date")
        }

        guard let identifier = message.identifier else {
            throw GmailServiceError.missingMessageInfo("id")
        }

        let attachmentsIds = payload.parts?.compactMap { $0.body?.attachmentId } ?? []
        let labelTypes: [MessageLabelType] = message.labelIds?.map(MessageLabelType.init) ?? []
        let labels = labelTypes.map(MessageLabel.init)

        var sender: String?
        var subject: String?
        var recipient: String?
        var cc: String?
        var bcc: String?

        messageHeaders.compactMap { $0 }.forEach {
            guard let name = $0.name?.lowercased() else { return }
            let value = $0.value
            switch name {
            case .from: sender = value
            case .subject: subject = value
            case .to: recipient = value
            case .cc: cc = value
            case .bcc: bcc = value
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
            threadId: message.threadId,
            draftIdentifier: draftIdentifier,
            raw: message.raw,
            recipient: recipient,
            cc: cc,
            bcc: bcc
        )
    }
}
