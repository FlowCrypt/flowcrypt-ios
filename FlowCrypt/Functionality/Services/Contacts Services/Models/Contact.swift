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
    /// public keys
    let pubKeys: [ContactKey]
    /// last time an email was sent to this contact, update when email is sent
    let lastUsed: Date?
}

extension Contact {
    init(_ contactObject: ContactObject, keyDetails: [KeyDetails] = []) {
        self.email = contactObject.email
        self.name = contactObject.name.nilIfEmpty
        self.pubKeys = keyDetails.map(ContactKey.init)
        self.lastUsed = contactObject.lastUsed
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

extension Contact: Equatable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.email == rhs.email
    }
}
