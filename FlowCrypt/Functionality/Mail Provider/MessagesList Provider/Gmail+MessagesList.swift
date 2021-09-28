//
//  Gmail_MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST
import GTMSessionFetcher
import Promises

extension GmailService: MessagesListProvider {
    func fetchMessages(using context: FetchMessageContext) -> Promise<MessageContext> {
        Promise { resolve, reject in
            let list = try awaitPromise(fetchMessagesList(using: context))
            let messageRequests: [Promise<Message>] = list.messages?.compactMap(\.identifier).map(fetchFullMessage(with:)) ?? []

            all(messageRequests)
                .then { messages in
                    let context = MessageContext(messages: messages, pagination: .byNextPage(token: list.nextPageToken))
                    resolve(context)
                }
                .catch { error in
                    reject(error)
                }
        }
    }
}

extension GmailService {
    private func fetchMessagesList(using context: FetchMessageContext) -> Promise<GTLRGmail_ListMessagesResponse> {
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

        return Promise { resolve, reject in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                    return
                }

                guard let messageList = data as? GTLRGmail_ListMessagesResponse else {
                    return reject(AppErr.cast("GTLRGmail_ListMessagesResponse"))
                }

                resolve(messageList)
            }
        }
    }

    private func fetchFullMessage(with identifier: String) -> Promise<Message> {
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: identifier)
        query.format = kGTLRGmailFormatFull
        return Promise { resolve, reject in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                    return
                }

                guard let gmailMessage = data as? GTLRGmail_Message else {
                    return reject(AppErr.cast("GTLRGmail_Message"))
                }

                do {
                    let message = try Message(gmailMessage)
                    resolve(message)
                } catch {
                    reject(error)
                }
            }
        }
    }
}

// MARK: - Gmail
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
            attachmentIds: attachmentsIds
        )
    }
}
