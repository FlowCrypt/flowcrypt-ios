//
//  ProcessedMessage.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/01/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct ProcessedMessage {
    enum MessageType: Hashable {
        case error(DecryptErr.ErrorType), encrypted, plain
    }

    enum MessageSignature: Hashable {
        case good, goodMixed, unsigned, error(String), missingPubkey(String), partial, bad, pending

        var message: String {
            switch self {
            case .good:
                return "message_signed".localized
            case .goodMixed:
                return "message_signature_good_mixed".localized
            case .unsigned:
                return "message_not_signed".localized
            case .error(let message):
                return "message_signature_verify_error".localizeWithArguments(message.lowercasingFirstLetter())
            case .missingPubkey(let longid):
                let message = "message_missing_pubkey".localizeWithArguments(longid)
                return "message_signature_verify_error".localizeWithArguments(message)
            case .partial:
                return "message_signature_partial".localized
            case .bad:
                return "message_bad_signature".localized
            case .pending:
                return "message_signature_pending".localized
            }
        }

        var icon: String {
            switch self {
            case .good, .goodMixed:
                return "lock"
            case .error, .missingPubkey, .partial:
                return "exclamationmark.triangle"
            case .unsigned, .bad:
                return "xmark"
            case .pending:
                return "clock"
            }
        }

        var color: UIColor {
            switch self {
            case .good, .goodMixed:
                return .main
            case .error, .missingPubkey, .partial:
                return .warningColor
            case .unsigned, .bad:
                return .errorColor
            case .pending:
                return .lightGray
            }
        }
    }

    let message: Message
    let text: String
    let messageType: MessageType
    var attachments: [MessageAttachment]
    var signature: MessageSignature?
}
