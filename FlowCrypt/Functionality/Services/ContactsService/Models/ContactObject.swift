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
    @objc dynamic var lastUsed: Date?

    let longids = List<LongId>()

    override class func primaryKey() -> String? { "email" }

    convenience init(
        email: String,
        name: String?,
        pubKey: String,
        pubKeyLastSig: Date?,
        pubkeyLastChecked: Date?,
        pubkeyExpiresOn: Date?,
        lastUsed: Date?,
        longids: [String]
    ) {
        self.init()
        self.email = email
        self.name = name ?? ""
        self.pubKey = pubKey
        self.pubkeyExpiresOn = pubkeyExpiresOn
        self.pubKeyLastSig = pubKeyLastSig
        self.pubkeyLastChecked = pubkeyLastChecked
        self.lastUsed = lastUsed

        longids
            .map(LongId.init)
            .forEach {
                self.longids.append($0)
            }
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
            longids: contact.longids
        )
    }
}
