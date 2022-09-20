//
//  MessageDraft.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 20/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

struct MessageDraft {
    let id: Identifier
    let threadId: String?
    let messageId: Identifier?
}

extension MessageDraft {
    init(gmailDraft: GTLRGmail_Draft) {
        self.id = Identifier(stringId: gmailDraft.identifier)
        self.threadId = gmailDraft.message?.threadId
        self.messageId = Identifier(stringId: gmailDraft.message?.identifier)
    }
}
