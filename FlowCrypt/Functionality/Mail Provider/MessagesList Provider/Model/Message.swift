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
    let recipients: [MessageRecipient]
    let cc: [MessageRecipient]
    let bcc: [MessageRecipient]
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
        raw: String? = nil,
        recipient: String? = nil,
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
        self.recipients = Message.parseRecipients(recipient)
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
    static func parseRecipients(_ string: String?) -> [MessageRecipient] {
        string?.components(separatedBy: ", ").map(MessageRecipient.init) ?? []
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

    var allRecipients: [MessageRecipient] {
        [recipients, cc, bcc].flatMap { $0 }
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

struct MessageRecipient: Hashable {
    let name: String?
    let email: String

    init(_ string: String) {
        let parts = string.components(separatedBy: " ")

        guard parts.count > 1, let email = parts.last else {
            self.name = nil
            self.email = string
            return
        }

        self.email = email.filter { !["<", ">"].contains($0) }
        let name = string
            .replacingOccurrences(of: email, with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespaces)
        self.name = name == self.email ? nil : name
    }
}

extension MessageRecipient {
    var displayName: String {
        name?.components(separatedBy: " ").first ??
        email.components(separatedBy: "@").first ??
        "unknown"
    }

    var rawString: (String?, String) { (name, email) }
}
