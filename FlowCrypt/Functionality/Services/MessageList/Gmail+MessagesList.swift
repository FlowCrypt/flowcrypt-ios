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
    func fetchMessages(for folderPath: String, count: Int, using pagination: MessagesListPagination) -> Promise<MessageContext> {
        Promise { (resolve, reject) in
            let list = try await(fetchMessagesList(for: folderPath, count: count, using: pagination))
            let messageRequests: [Promise<Message>] = list.messages?.compactMap(\.identifier).map(fetchMessage(with:)) ?? []
            all(messageRequests)
                .then { messages in
                    resolve(MessageContext(messages: messages, pagination: .byNextPage(token: "")))
                }
                .catch { error in
                    reject(error)
                }
        }
    }

    private func fetchMessagesList(for folderPath: String, count: Int, using pagination: MessagesListPagination) -> Promise<GTLRGmail_ListMessagesResponse> {
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
                }

                guard let messageList = data as? GTLRGmail_ListMessagesResponse else {
                    return reject(AppErr.cast("GTLRGmail_ListMessagesResponse"))
                }
                resolve(messageList)
            }
        }
    }

    private func fetchMessage(with id: String) -> Promise<Message> {
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: .me, identifier: id)
        return Promise { (resolve, reject) in
            self.gmailService.executeQuery(query) { (_, data, error) in
                if let error = error {
                    reject(AppErr.providerError(error))
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


private extension String {
    static let from = "from"
    static let subject = "subject"
    static let date = "date"
}

// MARK: - Gmail
private extension Message {
    init(_ message: GTLRGmail_Message) throws {
        guard let payload = message.payload else {
            throw GmailServiceError.missedMessagePayload
        }

        guard let messageHeaders = payload.headers else {
            throw GmailServiceError.missedMessageHeader
        }

        var sender: String?
        var subject: String?
        var dateString: String?

        var isMessageRead = true
        var size = 1

        messageHeaders.compactMap { $0 }.forEach {
            guard let name = $0.name?.lowercased() else { return }
            let value = $0.value
            switch name {
            case .from: sender = value
            case .subject: subject = value
            case .date: dateString = value
            default: break
            }
        }

        if let date = dateString {
            print("^^ date \(date)")
            let df = DateFormatter()
            let date = df.date(from: date)
            print(date)
        }

        self.init(
            date: Date(),
            sender: sender,
            subject: subject,
            isMessageRead: isMessageRead,
            size: nil
        )
    }
}
