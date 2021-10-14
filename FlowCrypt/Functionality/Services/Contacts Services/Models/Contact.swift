//
//  Contact.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct Contact {
    let email: String
    /// name if known
    let name: String?
    /// last time an email was sent to this contact, update when email is sent
    let lastUsed: Date?
    /// public keys
    var pubKeys: [ContactKey]
}

extension Contact {
    init(_ contactObject: ContactObject, keyDetails: [KeyDetails] = []) {
        self.email = contactObject.email
        self.name = contactObject.name.nilIfEmpty
        self.lastUsed = contactObject.lastUsed
        self.pubKeys = keyDetails.map(ContactKey.init)
    }
}

extension Contact {
    init(email: String, keyDetails: [KeyDetails]) {
        self.email = email
        self.name = keyDetails.first?.users.first ?? email
        self.lastUsed = nil
        self.pubKeys = keyDetails.map(ContactKey.init)
    }
}

extension Contact {
    mutating func remove(pubKey: ContactKey) {
        pubKeys.removeAll(where: { $0 == pubKey })
    }
}

extension Contact: Equatable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.email == rhs.email
    }
}
