//
//  InboxRenderable.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 11.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct InboxRenderable {
    enum WrappedType: Equatable {
        case message(Message)
        case thread(MessageThread)
    }

    let title: String
    let messageCount: Int
    let subtitle: String
    let dateString: String
    var isRead: Bool

    let date: Date

    let wrappedType: WrappedType
}

extension InboxRenderable {
    var wrappedMessage: Message? {
        guard case .message(let message) = wrappedType else {
            return nil
        }
        return message
    }
}

extension InboxRenderable {

    init(message: Message) {
        self.title = message.sender?.shortName ?? "message_unknown_sender".localized
        self.messageCount = 1
        self.subtitle = message.subject ?? "message_missing_subject".localized
        self.dateString = DateFormatter().formatDate(message.date)
        self.isRead = message.isMessageRead
        self.date = message.date
        self.wrappedType = .message(message)
    }

    init(thread: MessageThread, folderPath: String?, activeUserEmail: String) {

        self.title = InboxRenderable.messageTitle(activeUserEmail: activeUserEmail, with: thread, and: folderPath)

        self.messageCount = thread.messages.count
        self.subtitle = thread.subject ?? "message_missing_subject".localized
        self.isRead = !thread.messages
            .map(\.isMessageRead)
            .contains(false)
        let date = thread.messages.last?.date
        if let date = date {
            self.dateString = DateFormatter().formatDate(date)
        } else {
            self.dateString = ""
        }
        self.date = date ?? Date()
        self.wrappedType = .thread(thread)
    }

    private static func messageTitle(activeUserEmail: String, with thread: MessageThread, and folderPath: String?) -> String {
        // for now its not exactly clear how titles on other folders should looks like
        // so in scope of this PR we are applying this title presentation only for "sent" folder
        if folderPath == MessageLabelType.sent.value {
            let recipients = thread.messages
                .flatMap(\.allRecipients)
                .map(\.shortName)
                .unique()
                .joined(separator: ", ")
            return "To: \(recipients)"

        } else {
            return thread.messages
                .compactMap(\.sender?.shortName)
                .unique()
                .joined(separator: ",")
        }
    }
}
