//
//  Contact.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct RecipientWithSortedPubKeys {
    let email: String
    /// name if known
    let name: String?
    /// last time an email was sent to this contact, update when email is sent
    let lastUsed: Date?
    /// sorted public keys
    var pubKeys: [PubKey] {
        get { sortedPubKeys }
        set { _pubKeys = newValue }
    }
    /// non-sorted public keys
    private var _pubKeys: [PubKey]
}

extension RecipientWithSortedPubKeys {
    init(_ recipientObject: RecipientObject, keyDetails: [KeyDetails] = []) {
        self.email = recipientObject.email
        self.name = recipientObject.name.nilIfEmpty
        self.lastUsed = recipientObject.lastUsed
        self._pubKeys = keyDetails.map(PubKey.init)
    }
}

extension RecipientWithSortedPubKeys {
    init(email: String, keyDetails: [KeyDetails]) {
        self.email = email
        self.name = keyDetails.first?.users.first ?? email
        self.lastUsed = nil
        self._pubKeys = keyDetails.map(PubKey.init)
    }
}

extension RecipientWithSortedPubKeys {
    mutating func remove(pubKey: PubKey) {
        pubKeys.removeAll(where: { $0 == pubKey })
    }

    var keyState: PubKeyState { pubKeys.first?.keyState ?? .empty }
    var activePubKeys: [PubKey] { pubKeys.filter { $0.keyState == .active } }

    func pubKey(with longid: String) -> PubKey? {
        activePubKeys.first(where: { $0.longids.contains(longid) })
    }

    private var sortedPubKeys: [PubKey] {
        _pubKeys
            .sorted(by: { key1, key2 in
                // check if key1 is revoked
                guard !key1.isRevoked else { return false }
                // check if key2 is revoked
                guard !key2.isRevoked else { return true }
                // check if key1 never expires
                guard let expire1 = key1.expiresOn else { return true }
                // check if key2 never expires
                guard let expire2 = key2.expiresOn else { return false }
                // compare expire dates
                return expire1 > expire2
            })
    }

}

extension RecipientWithSortedPubKeys: Equatable {
    static func == (lhs: RecipientWithSortedPubKeys, rhs: RecipientWithSortedPubKeys) -> Bool {
        lhs.email == rhs.email
    }
}
