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
    let replyTo: [Recipient]
    let subject: String?
    let size: Int?
    let attachmentIds: [String]
    var attachments: [MessageAttachment]
    let threadId: String?
    let draftIdentifier: String?
    let raw: String?
    let body: MessageBody
    let inReplyTo: String?
    private(set) var labels: [MessageLabel]

    var isMessageRead: Bool {
        // imap
        if labels.contains(.none) {
            return false
        }
        // gmail
        if labels.contains(.unread) {
            return false
        }
        return true
    }

    var isPgp: Bool {
        body.text.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "-----BEGIN PGP ")
    }

    init(
        identifier: Identifier,
        date: Date,
        sender: Recipient?,
        subject: String?,
        size: Int?,
        labels: [MessageLabel],
        attachmentIds: [String],
        body: MessageBody,
        attachments: [MessageAttachment] = [],
        threadId: String? = nil,
        draftIdentifier: String? = nil,
        raw: String? = nil,
        to: String? = nil,
        cc: String? = nil,
        bcc: String? = nil,
        replyTo: String? = nil,
        inReplyTo: String? = nil
    ) {
        self.identifier = identifier
        self.date = date
        self.sender = sender
        self.subject = subject
        self.size = size
        self.labels = labels
        self.attachmentIds = attachmentIds
        self.attachments = attachments
        self.body = body
        self.threadId = threadId
        self.draftIdentifier = draftIdentifier
        self.raw = raw
        self.to = Message.parseRecipients(to)
        self.cc = Message.parseRecipients(cc)
        self.bcc = Message.parseRecipients(bcc)
        self.replyTo = Message.parseRecipients(replyTo)
        self.inReplyTo = inReplyTo
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
    mutating func markAsRead(_ isRead: Bool) {
        if isRead {
            update(labelsToRemove: [.unread, .none])
        } else {
            update(labelsToAdd: [.unread, .none])
        }
    }

    var allRecipients: [Recipient] {
        [to, cc, bcc].flatMap { $0 }
    }
}

extension Message {
    mutating func update(
        labelsToAdd: [MessageLabel] = [],
        labelsToRemove: [MessageLabel] = []
    ) {
        labels.removeAll(where: { labelsToRemove.contains($0) })
        labels.append(contentsOf: labelsToAdd)
    }
}

struct Identifier: Equatable, Hashable {
    let stringId: String?
    let intId: Int?

    init(stringId: String? = nil, intId: Int? = nil) {
        self.stringId = stringId
        self.intId = intId
    }

    static var random: Identifier {
        Identifier(stringId: UUID().uuidString, intId: nil)
    }
}
struct MessageBody: Hashable {
    let text: String
    let html: String?
}
