//
//  Contact.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct RecipientWithPubKeys {
    let email: String
    /// name if known
    let name: String?
    /// last time an email was sent to this contact, update when email is sent
    let lastUsed: Date?
    /// public keys
    var pubKeys: [PubKey]
}

extension RecipientWithPubKeys {
    init(_ recipientObject: RecipientObject, keyDetails: [KeyDetails] = []) {
        self.email = recipientObject.email
        self.name = recipientObject.name.nilIfEmpty
        self.lastUsed = recipientObject.lastUsed
        self.pubKeys = keyDetails.map(PubKey.init)
    }
}

extension RecipientWithPubKeys {
    init(email: String, keyDetails: [KeyDetails]) {
        self.email = email
        self.name = keyDetails.first?.users.first ?? email
        self.lastUsed = nil
        self.pubKeys = keyDetails.map(PubKey.init)
    }
}

extension RecipientWithPubKeys {
    mutating func remove(pubKey: PubKey) {
        pubKeys.removeAll(where: { $0 == pubKey })
    }

    var keyState: PubKeyState { pubKeys.first?.keyState ?? .empty }
}

extension RecipientWithPubKeys: Equatable {
    static func == (lhs: RecipientWithPubKeys, rhs: RecipientWithPubKeys) -> Bool {
        lhs.email == rhs.email
    }
}
