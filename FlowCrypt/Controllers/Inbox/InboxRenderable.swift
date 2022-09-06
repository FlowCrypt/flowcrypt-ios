//
//  InboxRenderable.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 11.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct InboxRenderable: Equatable {
    enum WrappedType: Equatable {
        case message(Message)
        case thread(MessageThread)
    }

    let title: String
    let messageCount: Int
    let subtitle: String
    let dateString: String
    var badge: String?
    var isRead: Bool

    let date: Date

    var wrappedType: WrappedType

    private let folderPath: String?
}

extension InboxRenderable {
    var wrappedMessage: Message? {
        guard case .message(let message) = wrappedType else {
            return nil
        }
        return message
    }
    var wrappedThread: MessageThread? {
        guard case .thread(let thread) = wrappedType else {
            return nil
        }
        return thread
    }
}

extension InboxRenderable {

    init(message: Message) {
        self.title = Self.messageTitle(for: message)
        self.messageCount = 1
        if let subject = message.subject, subject.hasContent {
            self.subtitle = subject
        } else {
            self.subtitle = "message_missing_subject".localized
        }

        self.dateString = DateFormatter().formatDate(message.date)
        self.isRead = message.isMessageRead
        self.date = message.date
        self.wrappedType = .message(message)
        self.badge = nil
        self.folderPath = nil
    }

    init(thread: MessageThread, folderPath: String?) {

        self.title = Self.messageTitle(for: thread, folderPath: folderPath)

        self.messageCount = thread.messages.count
        self.subtitle = thread.subject ?? "message_missing_subject".localized
        self.isRead = thread.isRead
        let date = thread.messages.last?.date
        if let date = date {
            self.dateString = DateFormatter().formatDate(date)
        } else {
            self.dateString = ""
        }
        self.date = date ?? Date()
        self.wrappedType = .thread(thread)
        self.folderPath = folderPath

        self.updateBadge()
    }

    private static func messageTitle(for thread: MessageThread, folderPath: String?) -> String {
        if folderPath == MessageLabel.sent.value || folderPath == MessageLabel.draft.value {
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

    private static func messageTitle(for message: Message) -> String {
        if message.labels.contains(.draft) {
            let recipients = message.allRecipients.map(\.shortName).joined(separator: ", ")
            return recipients.isEmpty ? "" : "To: \(recipients)"
        } else {
            return message.sender?.shortName ?? "message_unknown_sender".localized
        }
    }

    mutating func updateMessage(labelsToAdd: [MessageLabel], labelsToRemove: [MessageLabel]) {
        switch wrappedType {
        case .thread(var thread):
            thread.update(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)
            wrappedType = .thread(thread)
        case .message(var message):
            message.update(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)
            wrappedType = .message(message)
        }

        updateBadge()
    }

    mutating func updateBadge() {
        // show 'inbox' badge in 'All Mail' folder
        switch wrappedType {
        case .thread(let thread):
            self.badge = folderPath.isEmptyOrNil && thread.isInbox
                ? "folder_all_inbox".localized.lowercased()
                : nil
        case .message:
            self.badge = nil
        }
    }
}
