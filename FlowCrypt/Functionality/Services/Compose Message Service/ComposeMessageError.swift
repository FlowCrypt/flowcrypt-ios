//
//  ComposeMessageError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum MessageValidationError: Error, CustomStringConvertible, Equatable {
    case emptyRecipient
    case emptySubject
    case emptyMessage
    case weakPassword
    case subjectContainsPassword
    case notUniquePassword
    case noUsableAccountKeys
    case noPubRecipients
    case revokedKeyRecipients
    case expiredKeyRecipients
    case invalidEmailRecipient
    case internalError(String)

    var description: String {
        switch self {
        case .emptyRecipient:
            return "compose_enter_recipient".localized
        case .emptySubject:
            return "compose_enter_subject".localized
        case .emptyMessage:
            return "compose_enter_secure".localized
        case .weakPassword:
            return "compose_password_weak".localized
        case .subjectContainsPassword:
            return "compose_password_subject_error".localized
        case .notUniquePassword:
            return "compose_password_passphrase_error".localized
        case .noUsableAccountKeys:
            return "compose_no_sender_pub_usable".localized
        case .noPubRecipients:
            return "compose_recipient_no_pub".localized
        case .revokedKeyRecipients:
            return "compose_recipient_revoked".localized
        case .expiredKeyRecipients:
            return "compose_recipient_expired".localized
        case .invalidEmailRecipient:
            return "compose_recipient_invalid_email".localized
        case let .internalError(message):
            return message
        }
    }
}

enum ComposeMessageError: Error, CustomStringConvertible {
    case validationError(MessageValidationError)
    case passPhraseRequired
    case passPhraseNoMatch
    case gatewayError(Error)
    case missingPassPhrase(Keypair)
    case noKeysFoundForSign(Int, String)

    var description: String {
        switch self {
        case let .validationError(messageValidationError):
            return messageValidationError.description
        case .passPhraseRequired:
            return "compose_sign_passphrase_required".localized
        case .passPhraseNoMatch:
            return "compose_sign_passphrase_no_match".localized
        case let .noKeysFoundForSign(count, sender):
            return "compose_sign_no_keys".localizeWithArguments("\(count)", sender)
        case let .gatewayError(error):
            return error.localizedDescription
        default:
            return errorMessage
        }
    }
}
