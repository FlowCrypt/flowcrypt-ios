//
//  InboxItem.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 11.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct InboxItem: Equatable {
    var messages: [Message]
    let folderPath: String
    let type: InboxItemType

    enum InboxItemType: Equatable {
        case message(Identifier), thread(Identifier)
    }
}

extension InboxItem {
    var threadId: String? {
        switch type {
        case let .thread(id):
            return id.stringId
        case .message:
            return nil
        }
    }

    var subject: String? {
        messages
            .compactMap(\.subject)
            .first(where: { $0.isNotEmpty })
    }

    var labels: Set<MessageLabel> {
        Set(messages.flatMap(\.labels))
    }

    var isInbox: Bool {
        labels.contains(.inbox)
    }

    var isTrash: Bool {
        labels.contains(.trash)
    }

    var isDraft: Bool {
        messages.count == 1 && labels.contains(.draft)
    }

    var shouldShowMoveToInboxButton: Bool {
        guard let firstMessageLabels = messages.first?.labels else {
            return false
        }
        // Thread is treated as archived when labels don't contain `inbox` and first message label doesn't contain sent label
        // https://github.com/FlowCrypt/flowcrypt-ios/pull/1769#discussion_r931874353
        return !isInbox && !firstMessageLabels.contains(.sent)
    }

    var isRead: Bool {
        !messages.contains(where: { !$0.isRead })
    }

    var subtitle: String {
        if let subject, subject.hasContent {
            return subject
        } else {
            return "message_missing_subject".localized
        }
    }

    var date: Date {
        latestMessageDate(with: folderPath)
    }

    var dateString: String {
        DateFormatter().formatDate(date)
    }

    var recipients: [String] {
        messages
            .flatMap(\.allRecipients)
            .map(\.shortName)
            .unique()
    }

    var senderNames: [String] {
        messages.compactMap(\.sender?.shortName).unique()
    }

    var title: NSAttributedString {
        let style: NSAttributedString.Style = isRead
            ? .regular(17)
            : .bold(17)

        let textColor: UIColor = isRead
            ? .lightGray
            : .mainTextUnreadColor

        if folderPath == MessageLabel.sent.value || folderPath == MessageLabel.draft.value {
            let recipientsList = recipients.joined(separator: ",")
            return "To: \(recipientsList)".attributed(style, color: textColor)
        } else {
            let hasDrafts = messages.contains(where: \.isDraft)

            let sendersList = senderNames
                .joined(separator: ",")
                .attributed(style, color: textColor)

            if hasDrafts {
                let draftLabel = "draft".localized
                    .attributed(style, color: .systemRed.withAlphaComponent(0.75))
                let title = sendersList.mutable()
                title.append(",".attributed(style, color: textColor))
                title.append(draftLabel)
                return title
            } else {
                return sendersList
            }
        }
    }

    var badge: String? {
        guard isInbox, folderPath.isEmpty || folderPath == MessageLabel.draft.value
        else {
            return nil
        }

        return "folder_all_inbox".localized.lowercased()
    }

    func messages(with label: String?) -> [Message] {
        guard let label, !label.isEmpty else { return messages }

        let messageLabel = MessageLabel(gmailLabel: label)
        return messages.filter { $0.labels.contains(messageLabel) }
    }

    func latestMessageDate(with label: String?) -> Date {
        messages(with: label).map(\.date).max() ?? .distantPast
    }
}

extension InboxItem {
    init(message: Message) {
        self.messages = [message]
        self.folderPath = ""
        self.type = .message(message.identifier)
    }

    init(thread: MessageThread, folderPath: String?, identifier: MessageIdentifier? = nil) {
        self.messages = thread.messages
        self.folderPath = folderPath ?? ""
        self.type = .thread(Identifier(stringId: thread.identifier))

        if let draftId = identifier?.draftId, let messageId = identifier?.messageId {
            guard let index = self.messages.firstIndex(where: { $0.identifier == messageId }) else { return }
            self.messages[index].draftId = draftId
        }
    }

    mutating func update(labelsToAdd: [MessageLabel] = [], labelsToRemove: [MessageLabel] = []) {
        for index in messages.indices {
            messages[index].update(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)
        }
    }

    mutating func markAsRead(_ isRead: Bool) {
        if isRead {
            update(labelsToRemove: [.unread, .none])
        } else {
            update(labelsToAdd: [.unread, .none])
        }
    }
}

extension [InboxItem] {
    func firstIndex(with messageIdentifier: MessageIdentifier) -> Int? {
        firstIndex(where: {
            switch $0.type {
            case let .thread(threadId):
                return threadId == messageIdentifier.threadId
            case let .message(messageId):
                return messageId == messageIdentifier.messageId
            }
        })
    }
}
