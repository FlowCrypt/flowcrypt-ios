//
//  ComposeMessageRecipient.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct ComposeMessageRecipient {
    let email: String
    let name: String?
    var state: RecipientState
    var keyState: PubKeyState?
}

extension ComposeMessageRecipient: Equatable {
    static func == (lhs: ComposeMessageRecipient, rhs: ComposeMessageRecipient) -> Bool {
        return lhs.email == rhs.email
    }
}
