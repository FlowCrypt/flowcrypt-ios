//
//  Contact.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct Contact {
    let email: String
    /// name if known
    let name: String?
    /// public key
    let pubKey: String
    /// will be provided later
    let pubKeyLastSig: Date?
    /// the date when pubkey was retrieved from Attester, or nil
    let pubkeyLastChecked: Date?
    /// pubkey expiration date
    let pubkeyExpiresOn: Date?
    /// all pubkey longids, comma-separated
    let longids: [String]
    /// last time an email was sent to this contact, update when email is sent
    let lastUsed: Date?

    var longid: String? { longids.first }
}

extension Contact {
    init(_ contactObject: ContactObject) {
        self.email = contactObject.email
        self.name = contactObject.name.nilIfEmpty
        self.pubKey = contactObject.pubKey
        self.pubKeyLastSig = contactObject.pubKeyLastSig
        self.pubkeyLastChecked = contactObject.pubkeyLastChecked
        self.pubkeyExpiresOn = contactObject.pubkeyExpiresOn
        self.lastUsed = contactObject.lastUsed
        self.longids = contactObject.longids.map { $0.value }
    }
}
