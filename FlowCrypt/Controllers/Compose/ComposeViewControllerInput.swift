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
        let recipients: [String]
        let sender: String?
        let subject: String?
        let mime: Data?
        let sentDate: Date
        let message: String
        let threadId: String?
        let attachments: [MessageAttachment]
    }

    enum InputType: Equatable {
        case idle
        case reply(MessageQuoteInfo)
        case forward(MessageQuoteInfo)
    }

    let type: InputType

    var quoteRecipients: [String] {
        guard case .reply(let info) = type else {
            return []
        }
        return info.recipients
    }

    var subject: String? {
        type.info?.subject
    }

    var replyToMime: Data? {
        type.info?.mime
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
        case .idle:
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
        type != .idle
    }

    var isIdle: Bool {
        !isQuote
    }

    var isReply: Bool {
        guard case .reply = type else {
            return false
        }
        return true
    }

    var isForward: Bool {
        guard case .forward = type else {
            return false
        }
        return true
    }
}

extension ComposeMessageInput.InputType {
    var info: ComposeMessageInput.MessageQuoteInfo? {
        switch self {
        case .idle:
            return nil
        case .reply(let info), .forward(let info):
            return info
        }
    }
}
