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
        messages.compactMap(\.subject)
            .first(where: { $0.isNotEmpty })
    }

    var labels: [MessageLabel] {
        messages.last?.labels ?? []
    }

    var isInbox: Bool {
        labels.contains(.inbox)
    }
}
