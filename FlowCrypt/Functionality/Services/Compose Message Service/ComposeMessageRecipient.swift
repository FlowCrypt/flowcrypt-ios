//
//  ComposeMessageRecipient.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct ComposeMessageRecipient: RecipientBase {
    let email: String
    let name: String?
    let type: RecipientType
    var state: RecipientState
    var keyState: PubKeyState?
}

extension ComposeMessageRecipient: Equatable {
    static func == (lhs: ComposeMessageRecipient, rhs: ComposeMessageRecipient) -> Bool {
        return lhs.email == rhs.email && lhs.type == rhs.type
    }
}

enum RecipientType: String, CaseIterable, Hashable {
    case to, cc, bcc
}

extension RecipientType {
    var inputPlaceholder: String {
        "compose_recipient_\(rawValue)".localized
    }
}
