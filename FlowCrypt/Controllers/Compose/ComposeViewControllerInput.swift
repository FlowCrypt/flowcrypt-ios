//
//  ComposeViewControllerInput.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension ComposeViewController {
    struct Input {
        static let empty = Input(type: .idle)

        struct ReplyInfo: Equatable {
            let recipient: String?
            let subject: String?
            let mime: Data?
            let sentDate: Date
            let message: String
        }

        enum InputType: Equatable {
            case idle
            case reply(ReplyInfo)
        }

        let type: InputType

        var isReply: Bool {
            switch type {
            case .idle: return false
            case .reply: return true
            }
        }

        var recipientReplyTitle: String? {
            guard case let .reply(info) = type else { return nil }
            return info.recipient
        }

        var subjectReplyTitle: String? {
            guard case let .reply(info) = type else { return nil }
            return "Re: \(info.subject ?? "(no subject)")"
        }

        var successfullySentToast: String {
            switch type {
            case .idle: return "compose_sent".localized
            case .reply: return "compose_reply_successfull".localized
            }
        }

        var subject: String? {
            guard case let .reply(info) = type else { return nil }
            return info.subject
        }

        var replyToMime: Data? {
            guard case let .reply(info) = type else { return nil }
            return info.mime
        }
    }
}
