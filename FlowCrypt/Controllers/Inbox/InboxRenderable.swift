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
        self.title = message.sender ?? "message_unknown_sender".localized
        self.messageCount = 1
        self.subtitle = message.subject ?? "message_missed_subject".localized
        self.dateString = DateFormatter().formatDate(message.date)
        self.isRead = message.isMessageRead
        self.date = message.date
        self.wrappedType = .message(message)
    }

    init(thread: MessageThread, folderPath: String) {

        self.title = InboxRenderable.messageTitle(with: thread, and: folderPath)

        self.messageCount = thread.messages.count
        self.subtitle = thread.subject ?? "message_missed_subject".localized
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

    private static func messageTitle(with thread: MessageThread, and folderPath: String) -> String {
        guard let myEmail = DataService.shared.email else { return "" }

        // for now its not exactly clear how titles on other folders should looks like
        // so in scope of this PR we are applying this title presentation only for "sent" folder
        if folderPath == MessageLabelType.sent.value {
            var emails = thread.messages.compactMap(\.sender).unique()
            // if we have only one email, it means that it could be "me" and we are not
            // clearing our own email from that
            if emails.count > 1 {
                if let i = emails.firstIndex(of: myEmail) {
                    emails.remove(at: i)
                }
            }
            let recipients = emails
                .compactMap { $0.components(separatedBy: "@").first }
                .joined(separator: ",")
            return "To: \(recipients)"

        } else {
            return thread.messages
                .compactMap(\.sender)
                .compactMap { $0.components(separatedBy: "@").first }
                .unique()
                .joined(separator: ",")
        }
    }
}
