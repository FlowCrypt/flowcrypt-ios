//
//  ComposeMessageService+State.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension ComposeMessageService {
    enum State {
        case idle
        case validatingMessage
        case startComposing
        case progressChanged(Float)
        case messageSent

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
            case .messageSent:
                return "compose_message_sent".localized
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
