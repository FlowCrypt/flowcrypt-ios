//
//  Gmail_MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: MessagesListProvider {
    func fetchMessages(
        for folderPath: String,
        count: Int,
        using pagination: MessagesListPagination
    ) -> Promise<MessageContext> {
        Promise { (resolve, reject) in
            let list = try await(fetchMessagesList(for: folderPath, count: count, using: pagination))
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

    private func fetchMessagesList(
        for folderPath: String,
        count: Int,
        using pagination: MessagesListPagination
    ) -> Promise<GTLRGmail_ListMessagesResponse> {
        guard case let .byNextPage(token) = pagination else {
            fatalError("Pagination \(pagination) is not supported for this provider")
        }
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: .me)
        query.labelIds = [folderPath]
        query.maxResults = UInt(count)
        query.pageToken = token

        return Promise { (resolve, reject) in
            self.gmailService.executeQuery(query) { (_, data, error) in
                if let error = error {
                    reject(AppErr.providerError(error))
                    return
                }

                guard let messageList = data as? GTLRGmail_ListMessagesResponse else {
                    return reject(AppErr.cast("GTLRGmail_ListMessagesResponse"))
                }

                resolve(messageList)
            }
        }
    }

    private func fetchFullMessage(with id: String) -> Promise<Message> {
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: id)
        query.format = kGTLRGmailFormatFull
        return Promise { (resolve, reject) in
            self.gmailService.executeQuery(query) { (_, data, error) in
                if let error = error {
                    reject(AppErr.providerError(error))
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

        guard let id = message.identifier else {
            throw GmailServiceError.missedMessageInfo("id")
        }

        let labelTypes: [MessageLabelType] = message.labelIds?.map(MessageLabelType.init) ?? []
        let labels = labelTypes.map(MessageLabel.init)

        var sender: String?
        var subject: String?

        print("^^ \(String(describing: message.labelIds))")
        messageHeaders.compactMap { $0 }.forEach {
            guard let name = $0.name?.lowercased() else { return }
            let value = $0.value
            switch name {
            case .from: sender = value
            case .subject: subject = value
            default: break
            }
        }

        self.init(
            identifier: Identifier(stringId: id),
            date: Date(timeIntervalSince1970: internalDate),
            sender: sender,
            subject: subject,
            size: message.sizeEstimate.flatMap(Int.init),
            labels: labels
        )
    }
}
