//
//  ComposeViewControllerInput.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct ComposeMessageInput: Equatable {
    static let empty = ComposeMessageInput(type: .idle)

    struct MessageQuoteInfo: Equatable {
        let id: Identifier?
        let recipients: [Recipient]
        let ccRecipients: [Recipient]
        let bccRecipients: [Recipient]
        let sender: Recipient?
        let subject: String?
        let sentDate: Date
        let text: String
        let threadId: String?
        let replyToMsgId: String?
        let inReplyTo: String?
        let rfc822MsgId: String?
        let shouldEncrypt: Bool
        let attachments: [MessageAttachment]
    }

    enum InputType: Equatable {
        case idle
        case reply(MessageQuoteInfo)
        case forward(MessageQuoteInfo)
        case draft(MessageQuoteInfo)
    }

    let type: InputType

    var subject: String? {
        type.info?.subject
    }

    var text: String? {
        type.info?.text
    }

    var isPgp: Bool {
        text?.isPgp ?? false
    }

    var replyToMsgId: String? {
        type.info?.replyToMsgId
    }

    var inReplyTo: String? {
        type.info?.inReplyTo
    }

    var threadId: String? {
        type.info?.threadId
    }

    var attachments: [MessageAttachment] {
        type.info?.attachments ?? []
    }
}

extension ComposeMessageInput {
    var successfullySentToast: String {
        switch type {
        case .idle, .draft:
            return "compose_encrypted_sent".localized
        case .forward:
            return "compose_forward_successful".localized
        case .reply:
            return "compose_reply_successful".localized
        }
    }
}

extension ComposeMessageInput {
    var isQuote: Bool {
        switch type {
        case .reply, .forward:
            return true
        case .idle, .draft:
            return false
        }
    }

    var shouldFocusTextNode: Bool {
        switch type {
        case .reply:
            return true
        case .idle, .forward, .draft:
            return false
        }
    }
}

extension ComposeMessageInput.InputType {
    var info: ComposeMessageInput.MessageQuoteInfo? {
        switch self {
        case .idle:
            return nil
        case .reply(let info), .forward(let info), .draft(let info):
            return info
        }
    }
}

extension ComposeMessageInput.MessageQuoteInfo {
    init(message: Message, processed: ProcessedMessage? = nil) {
        self.id = message.identifier
        self.recipients = message.to
        self.ccRecipients = message.cc
        self.bccRecipients = message.bcc
        self.sender = message.sender
        self.subject = message.subject
        self.sentDate = message.date
        self.text = processed?.text ?? message.body.text
        self.threadId = message.threadId
        self.rfc822MsgId = message.rfc822MsgId
        self.replyToMsgId = message.replyToMsgId
        self.inReplyTo = message.inReplyTo
        self.shouldEncrypt = message.isPgp
        self.attachments = processed?.attachments ?? message.attachments
    }
}
