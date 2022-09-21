//
//  MessageThread.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageThreadContext {
    let threads: [MessageThread]
    let pagination: MessagesListPagination
}

struct MessageThread: Equatable {
    let identifier: String?
    let snippet: String?
    let path: String
    var messages: [Message]

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

    private func messages(with label: String?) -> [Message] {
        guard let label = label else { return messages }

        let messageLabel = MessageLabel(gmailLabel: label)
        return messages.filter { $0.labels.contains(messageLabel) }
    }

    func latestMessageDate(with label: String?) -> Date {
        messages(with: label).map(\.date).max() ?? .distantPast
    }
}

extension MessageThread {
    mutating func update(labelsToAdd: [MessageLabel], labelsToRemove: [MessageLabel]) {
        for index in messages.indices {
            messages[index].update(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)
        }
    }
}
