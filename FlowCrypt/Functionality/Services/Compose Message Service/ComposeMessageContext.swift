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
    var password: String?
    var attachments: [MessageAttachment] = []
}

extension ComposeMessageContext {
    var hasPassword: Bool {
        guard let password = password else { return false }
        return password.isNotEmpty
    }

    var hasRecipientsWithoutPubKeys: Bool {
        recipients.first(where: {
            if case .keyNotFound = $0.state { return true }
            return false
        }) != nil
    }
}
