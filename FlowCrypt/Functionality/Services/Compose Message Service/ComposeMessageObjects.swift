//
//  ComposeMessageObjects.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 11/5/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import Foundation

protocol CoreComposeMessageType {
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail
}

struct ComposeMessageContext: Equatable {
    var message: String?
    var recipients: [ComposeMessageRecipient] = []
    var subject: String?
    var attachments: [ComposeMessageAttachment] = []
}

struct ComposeMessageRecipient: Equatable {
    let email: String
    var state: RecipientState

    static func == (lhs: ComposeMessageRecipient, rhs: ComposeMessageRecipient) -> Bool {
        return lhs.email == rhs.email
    }
}
