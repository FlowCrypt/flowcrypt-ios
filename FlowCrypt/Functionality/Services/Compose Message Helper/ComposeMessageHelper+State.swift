//
//  ComposeMessageHelper+State.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension ComposeMessageHelper {
    enum State {
        case idle
        case validatingMessage
        case startComposing
        case progressChanged(Float)
        case messageSent(Bool)

        var message: String? {
            switch self {
            case .idle:
                return nil
            case .validatingMessage:
                return "validating_title".localized
            case .startComposing:
                return "encrypting_title".localized
            case .progressChanged:
                return "compose_uploading".localized
            case let .messageSent(isEncrypted):
                let label = isEncrypted ? "compose_encrypted_message_sent" : "compose_message_sent"
                return label.localized
            }
        }

        var progress: Float? {
            guard case let .progressChanged(progress) = self else {
                return nil
            }
            return progress
        }
    }
}
