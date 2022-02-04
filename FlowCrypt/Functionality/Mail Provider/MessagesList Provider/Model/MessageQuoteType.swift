//
//  MessageQuoteType.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 23/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum MessageQuoteType {
    case reply, forward
}

extension MessageQuoteType {
    var subjectPrefix: String {
        switch self {
        case .reply:
            return "re".localized
        case .forward:
            return "fwd".localized
        }
    }
}
