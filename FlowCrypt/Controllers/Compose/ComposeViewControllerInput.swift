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
        case quote(MessageQuoteInfo)
    }

    let type: InputType

    var isQuote: Bool {
        switch type {
        case .idle: return false
        case .quote: return true
        }
    }

    var quoteRecipients: [String] {
        guard case let .quote(info) = type else { return [] }
        return info.recipients
    }

    var successfullySentToast: String {
        switch type {
        case .idle: return "compose_encrypted_sent".localized
        case .quote(let info):
            if info.recipients.isEmpty {
                return "compose_forward_successful".localized
            } else {
                return "compose_reply_successful".localized
            }
        }
    }

    var subject: String? {
        guard case let .quote(info) = type else { return nil }
        return info.subject
    }

    var replyToMime: Data? {
        guard case let .quote(info) = type else { return nil }
        return info.mime
    }

    var threadId: String? {
        guard case let .quote(info) = type else { return nil }
        return info.threadId
    }

    var attachments: [MessageAttachment] {
        guard case let .quote(info) = type else { return [] }
        return info.attachments
    }
}
