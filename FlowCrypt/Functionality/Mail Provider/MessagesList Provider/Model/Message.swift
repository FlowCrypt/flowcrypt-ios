//
//  Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
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
    let rfc822MsgId: String?
    var draftId: Identifier?
    var raw: String?
    let body: MessageBody
    let inReplyTo: String?
    let replyToMsgId: String?
    let isSuspicious: Bool
    private(set) var labels: [MessageLabel]

    var isRead: Bool {
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

    var isDraft: Bool { labels.contains(.draft) }

    var isPgp: Bool {
        body.text.isPgp || hasSignatureAttachment || hasEncryptedMsgAttachment
    }

    var hasSignatureAttachment: Bool {
        attachments.contains(where: { $0.treatAs == "signature" })
    }

    var publicKeyAttachments: [MessageAttachment] {
        attachments.filter { $0.treatAs == "publicKey" }
    }

    var hasPublicKeyAttachment: Bool {
        publicKeyAttachments.isNotEmpty
    }

    var hasEncryptedMsgAttachment: Bool {
        attachments.contains(where: { $0.treatAs == "encryptedMsg" })
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
        rfc822MsgId: String? = nil,
        draftId: Identifier? = nil,
        raw: String? = nil,
        to: String? = nil,
        cc: String? = nil,
        bcc: String? = nil,
        replyTo: String? = nil,
        inReplyTo: String? = nil,
        replyToMsgId: String? = nil,
        isSuspicious: Bool = false
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
        self.rfc822MsgId = rfc822MsgId
        self.draftId = draftId
        self.raw = raw
        self.to = Self.parseRecipients(to)
        self.cc = Self.parseRecipients(cc)
        self.bcc = Self.parseRecipients(bcc)
        self.replyTo = Self.parseRecipients(replyTo)
        self.inReplyTo = inReplyTo
        self.replyToMsgId = replyToMsgId
        self.isSuspicious = isSuspicious
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
    var allRecipients: [Recipient] {
        [to, cc, bcc].flatMap { $0 }
    }

    mutating func markAsRead(_ isRead: Bool) {
        if isRead {
            update(labelsToRemove: [.unread, .none])
        } else {
            update(labelsToAdd: [.unread, .none])
        }
    }

    static func parseRecipients(_ string: String?) -> [Recipient] {
        string?.components(separatedBy: ", ").map(Recipient.init) ?? []
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

    static var random: Self {
        .init(stringId: UUID().uuidString, intId: nil)
    }
}

struct MessageBody: Hashable {
    let text: String
    let html: String?
    let attachment: MessageAttachment?
}

extension MessageBody {
    var hasNoContent: Bool {
        text.isEmpty && attachment == nil
    }
}
