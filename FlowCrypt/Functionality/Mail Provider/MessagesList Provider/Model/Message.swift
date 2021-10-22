//
//  Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import GoogleAPIClientForREST_Gmail

struct Message: Hashable {
    let identifier: Identifier
    let date: Date
    let sender: String?
    let subject: String?
    let size: Int?
    let attachmentIds: [String]
    let threadId: String?
    let draftIdentifier: String?
    let raw: String?
    private(set) var labels: [MessageLabel]

    var isMessageRead: Bool {
        let types = labels.map(\.type)
        // imap
        if types.contains(.none) {
            return false
        }
        // gmail
        if types.contains(.unread) {
            return false
        }
        return true
    }

    init(
        identifier: Identifier,
        date: Date,
        sender: String?,
        subject: String?,
        size: Int?,
        labels: [MessageLabel],
        attachmentIds: [String],
        threadId: String? = nil,
        draftIdentifier: String? = nil,
        raw: String? = nil
    ) {
        self.identifier = identifier
        self.date = date
        self.sender = sender
        self.subject = subject
        self.size = size
        self.labels = labels
        self.attachmentIds = attachmentIds
        self.threadId = threadId
        self.draftIdentifier = draftIdentifier
        self.raw = raw
    }
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension Message {
    func markAsRead(_ isRead: Bool) -> Message {
        var copy = self
        if isRead {
            copy.labels.removeAll(where: { $0.type == .unread || $0.type == .none })
        } else {
            copy.labels.append(MessageLabel(type: .unread))
            copy.labels.append(MessageLabel(type: .none))
        }
        return copy
    }
}

struct Identifier: Equatable, Hashable {
    let stringId: String?
    let intId: Int?

    init(stringId: String? = nil, intId: Int? = nil) {
        self.stringId = stringId
        self.intId = intId
    }
}
