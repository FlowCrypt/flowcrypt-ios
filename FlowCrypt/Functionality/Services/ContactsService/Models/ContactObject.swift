//
//  ContactObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

final class LongId: Object {
    @objc dynamic var value: String = ""

    convenience init(value: String) {
        self.init()
        self.value = value
    }
}

final class ContactObject: Object {
    @objc dynamic var email: String = ""
    @objc dynamic var pubKey: String = ""

    @objc dynamic var name: String?

    @objc dynamic var pubkeyExpiresOn: Date?
    @objc dynamic var pubKeyLastSig: Date?
    @objc dynamic var pubkeyLastChecked: Date?
    @objc dynamic var pubkeyCreated: Date?
    @objc dynamic var lastUsed: Date?

    /// all pubkey fingerprints, comma-separated
    @objc dynamic var fingerprints: String = ""
    @objc dynamic var keyAlgo: KeyAlgoObject?

    let longids = List<LongId>()

    convenience init(
        email: String,
        name: String?,
        pubKey: String,
        pubKeyLastSig: Date?,
        pubkeyLastChecked: Date?,
        pubkeyExpiresOn: Date?,
        lastUsed: Date?,
        pubkeyCreated: Date?,
        longids: [String],
        fingerprints: [String],
        algo: KeyAlgo?
    ) {
        self.init()
        self.email = email
        self.name = name ?? ""
        self.pubKey = pubKey
        self.pubkeyExpiresOn = pubkeyExpiresOn
        self.pubKeyLastSig = pubKeyLastSig
        self.pubkeyLastChecked = pubkeyLastChecked
        self.pubkeyCreated = pubkeyCreated
        self.lastUsed = lastUsed
        self.fingerprints = fingerprints.joined(separator: ",")

        if let algorithm = algo {
            self.keyAlgo = KeyAlgoObject(algo: algorithm)
        }

        longids
            .map(LongId.init)
            .forEach {
                self.longids.append($0)
            }
    }

    override class func primaryKey() -> String? {
        "email"
    }
}

extension ContactObject {
    convenience init(contact: Contact) {
        self.init(
            email: contact.email,
            name: contact.name,
            pubKey: contact.pubKey,
            pubKeyLastSig: contact.pubKeyLastSig,
            pubkeyLastChecked: contact.pubkeyLastChecked,
            pubkeyExpiresOn: contact.pubkeyExpiresOn,
            lastUsed: contact.lastUsed,
            pubkeyCreated: contact.pubkeyCreated,
            longids: contact.longids,
            fingerprints: contact.fingerprints,
            algo: contact.algo
        )
    }
}

extension ContactObject: CachedObject {
    var identifier: String { email }
}
