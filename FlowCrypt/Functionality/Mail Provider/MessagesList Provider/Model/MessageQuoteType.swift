//
//  MessageQuoteType.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 23/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum MessageQuoteType {
    case reply, replyAll, forward
}

extension MessageQuoteType {
    var subjectPrefix: String {
        switch self {
        case .reply, .replyAll:
            return "re".localized
        case .forward:
            return "fwd".localized
        }
    }

    var actionLabel: String {
        switch self {
        case .reply:
            return ""
        case .replyAll:
            return "message_reply_all".localized
        case .forward:
            return "forward".localized
        }
    }
}
