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
    let sender: Recipient?
    let to: [Recipient]
    let cc: [Recipient]
    let bcc: [Recipient]
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
        sender: Recipient?,
        subject: String?,
        size: Int?,
        labels: [MessageLabel],
        attachmentIds: [String],
        threadId: String? = nil,
        draftIdentifier: String? = nil,
        raw: String? = nil,
        to: String? = nil,
        cc: String? = nil,
        bcc: String? = nil
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
        self.to = Message.parseRecipients(to)
        self.cc = Message.parseRecipients(cc)
        self.bcc = Message.parseRecipients(bcc)
    }
}

extension Message: Equatable, Comparable {
    static func < (lhs: Message, rhs: Message) -> Bool {
        lhs.date > rhs.date
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension Message {
    static func parseRecipients(_ string: String?) -> [Recipient] {
        string?.components(separatedBy: ", ").map(Recipient.init) ?? []
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

    var allRecipients: [Recipient] {
        [to, cc, bcc].flatMap { $0 }
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
