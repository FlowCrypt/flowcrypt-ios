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
    var longid: String? { longids.first }

    /// last time an email was sent to this contact, update when email is sent
    let lastUsed: Date?

    /// all pubkey fingerprints, comma-separated
    let fingerprints: [String]
    /// first pubkey fingerprint
    var fingerprint: String? { fingerprints.first }

    /// pubkey created date
    let pubkeyCreated: Date?

    let algo: KeyAlgo?
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
        self.longids = contactObject.longids.map(\.value)
        self.fingerprints = contactObject.fingerprints.split(separator: ",").map(String.init)
        self.algo = contactObject.keyAlgo.flatMap(KeyAlgo.init)
        self.pubkeyCreated = contactObject.pubkeyCreated
    }
}

extension Contact {
    init(email: String, keyDetail: KeyDetails) {
        let keyIds = keyDetail.ids
        let longids = keyIds.map(\.longid)
        let fingerprints = keyIds.map(\.fingerprint)

        self.email = email
        self.name = keyDetail.users.first ?? email
        self.pubKey = keyDetail.public
        self.pubKeyLastSig = nil // TODO: - will be provided later
        self.pubkeyLastChecked = Date()
        self.pubkeyExpiresOn = nil // TODO: - will be provided later
        self.longids = longids
        self.lastUsed = nil
        self.fingerprints = fingerprints
        self.pubkeyCreated = Date(timeIntervalSince1970: Double(keyDetail.created))
        self.algo = keyDetail.algo
    }
}

extension Contact: Equatable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.email == rhs.email
    }
}
