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
            return "Re: "
        case .forward:
            return "Fwd: "
        }
    }
}
// TODO: - Anton - check in gmail re and fwd
