//
//  Gmail_MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
//

import FlowCryptCommon
import GoogleAPIClientForREST_Gmail

// TODO: - https://github.com/FlowCrypt/flowcrypt-ios/issues/669 Remove in scope of the ticket
extension GmailService: MessagesListProvider {
    func fetchMessages(using context: FetchMessageContext) async throws -> MessageContext {
        return try await withThrowingTaskGroup(of: Message.self) { taskGroup -> MessageContext in
            let list = try await fetchMessagesList(using: context)
            let messageIdentifiers = list.messages?.compactMap(\.identifier) ?? []

            for identifier in messageIdentifiers {
                taskGroup.addTask {
                    try await fetchFullMessage(with: identifier)
                }
            }

            var messages: [Message] = []
            for try await result in taskGroup {
                messages.append(result)
            }

            return MessageContext(
                messages: messages,
                pagination: .byNextPage(token: list.nextPageToken)
            )
        }
    }
}

extension GmailService {
    private func fetchMessagesList(using context: FetchMessageContext) async throws -> GTLRGmail_ListMessagesResponse {
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: .me)

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

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRGmail_ListMessagesResponse, Error>) in
            gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    continuation.resume(throwing: GmailServiceError.providerError(error))
                    return
                }

                guard let messageList = data as? GTLRGmail_ListMessagesResponse else {
                    continuation.resume(throwing: AppErr.cast("GTLRGmail_ListMessagesResponse"))
                    return
                }

                continuation.resume(returning: messageList)
            }
        }
    }

    private func fetchFullMessage(with identifier: String) async throws -> Message {
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: identifier)
        query.format = kGTLRGmailFormatFull
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Message, Error>) in
            gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    continuation.resume(throwing: GmailServiceError.providerError(error))
                    return
                }

                guard let gmailMessage = data as? GTLRGmail_Message else {
                    continuation.resume(throwing: AppErr.cast("GTLRGmail_Message"))
                    return
                }

                do {
                    continuation.resume(returning: try Message(gmailMessage))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
