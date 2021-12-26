//
//  ComposeMessageContext.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct ComposeMessageContext: Equatable {
    var message: String?
    var recipients: [ComposeMessageRecipient] = []
    var subject: String?
    var attachments: [MessageAttachment] = []
    var messagePassword: String? {
        get {
            (_messagePassword ?? "").isNotEmpty ? _messagePassword : nil
        }
        set { _messagePassword = newValue }
    }

    private var _messagePassword: String?
}

extension ComposeMessageContext {
    var hasMessagePassword: Bool {
        messagePassword != nil
    }

    var hasRecipientsWithoutPubKey: Bool {
        recipients.first { $0.keyState == .empty } != nil
    }

    var hasMessagePasswordIfNeeded: Bool {
        guard hasRecipientsWithoutPubKey else { return true }
        return hasMessagePassword
    }
}
