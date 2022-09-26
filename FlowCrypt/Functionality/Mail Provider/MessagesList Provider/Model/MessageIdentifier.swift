//
//  MessageDraft.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 20/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

struct MessageIdentifier {
    var draftId: Identifier?
    var threadId: Identifier?
    var messageId: Identifier?
    var draftMessageId: Identifier?
}

extension MessageIdentifier {
    init(gmailDraft: GTLRGmail_Draft) {
        self.draftId = Identifier(stringId: gmailDraft.identifier)
        self.threadId = Identifier(stringId: gmailDraft.message?.threadId)
        self.messageId = Identifier(stringId: gmailDraft.message?.identifier)
    }
}
