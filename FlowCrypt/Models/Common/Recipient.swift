//
//  Recipient.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 17.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct Recipient: RecipientBase {
    var email: String
    var name: String?
    var lastUsed: Date?
    var pubKeys: [PubKey]
}

extension Recipient {
    init(_ recipientObject: RecipientRealmObject) {
        self.email = recipientObject.email
        self.name = recipientObject.name
        self.lastUsed = recipientObject.lastUsed
        self.pubKeys = recipientObject.pubKeys.map(PubKey.init)
    }
}
