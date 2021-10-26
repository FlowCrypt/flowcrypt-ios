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
    case missedPublicKey
    case noPubRecipients([String])
    case revokedKeyRecipients
    case expiredKeyRecipients
    case internalError(String)

    var description: String {
        switch self {
        case .emptyRecipient:
            return "compose_enter_recipient".localized
        case .emptySubject:
            return "compose_enter_subject".localized
        case .emptyMessage:
            return "compose_enter_secure".localized
        case .missedPublicKey:
            return "compose_no_pub_sender".localized
        case .noPubRecipients:
            return "compose_recipient_no_pub".localized
        case .revokedKeyRecipients:
            return "compose_recipient_revoked".localized
        case .expiredKeyRecipients:
            return "compose_recipient_expired".localized
        case .internalError(let message):
            return message
        }
    }
}

enum ComposeMessageError: Error, CustomStringConvertible, Equatable {
    case validationError(MessageValidationError)
    case gatewayError(Error)

    var description: String {
        switch self {
        case .validationError(let messageValidationError):
            return messageValidationError.description
        case .gatewayError(let error):
            return error.localizedDescription
        }
    }

    static func == (lhs: ComposeMessageError, rhs: ComposeMessageError) -> Bool {
        lhs.description == rhs.description
    }
}
