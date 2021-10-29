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
    let subtitle: String
    let dateString: String
    var isRead: Bool

    let date: Date

    let wrappedType: WrappedType
}


extension InboxRenderable: Comparable {
    static func < (lhs: InboxRenderable, rhs: InboxRenderable) -> Bool {
        lhs.date > rhs.date
    }
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
        self.title = message.sender ?? "message_unknown_sender".localized
        self.subtitle = message.subject ?? "message_missed_subject".localized
        self.dateString = DateFormatter().formatDate(message.date)
        self.isRead = message.isMessageRead
        self.date = message.date
        self.wrappedType = .message(message)
    }

    init(thread: MessageThread) {
        let sender = thread.messages.compactMap(\.sender)
            .compactMap { $0.components(separatedBy: "@").first ?? "" }
            .unique()
            .joined(separator: ",")
        let messagesCount = thread.messages.count
        let amount = messagesCount == 1
            ? ""
            : " (\(messagesCount))"

        self.title = sender + amount
        self.subtitle = thread.subject ?? "message_missed_subject".localized

        if let date = thread.messages.first?.date {
            self.dateString = DateFormatter().formatDate(date)
        } else {
            self.dateString = ""
        }

        self.isRead = !thread.messages
            .map(\.isMessageRead)
            .contains(false)

        self.date = thread.messages.first?.date ?? Date()

        self.wrappedType = .thread(thread)
    }
}
