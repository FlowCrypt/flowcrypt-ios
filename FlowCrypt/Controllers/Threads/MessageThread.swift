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

    var isArchived: Bool {
        guard let firstMessageLabels = messages.first?.labels else {
            return false
        }
        // Thread is treaded as archived when first message label doesn't contain inbox & sent label
        return !firstMessageLabels.contains(.inbox) && !firstMessageLabels.contains(.sent)
    }

    var isRead: Bool {
        !messages.contains(where: { !$0.isMessageRead })
    }
}

extension MessageThread {
    mutating func update(labelsToAdd: [MessageLabel], labelsToRemove: [MessageLabel]) {
        for index in messages.indices {
            messages[index].update(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)
        }
    }
}
