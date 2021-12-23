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

    func hasRecipientsWithoutPubKey(withPasswordSupport: Bool) -> Bool {
        recipients
            .filter {
                if case .keyNotFound = $0.state { return true }
                return false
            }
            .first(where: {
                guard let domain = $0.email.recipientDomain else { return !withPasswordSupport }
                let domainsWithPasswordSupport = ["flowcrypt.com"]
                let supportsPassword = domainsWithPasswordSupport.contains(domain)
                return withPasswordSupport == supportsPassword
            }) != nil
    }
}
