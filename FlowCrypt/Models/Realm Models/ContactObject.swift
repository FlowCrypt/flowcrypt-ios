//
//  ContactObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class LongId: Object {
    @Persisted var value: String = ""

    convenience init(value: String) {
        self.init()
        self.value = value
    }
}

final class ContactObject: Object {
    @Persisted(primaryKey: true) var email: String = ""

    @Persisted var name: String?
    @Persisted var lastUsed: Date?
    @Persisted var pubKeys = List<ContactKeyObject>()

    convenience init(
        email: String,
        name: String?,
        lastUsed: Date?,
        keys: [ContactKey]
    ) {
        self.init()
        self.email = email
        self.name = name ?? ""
        self.lastUsed = lastUsed

        keys
            .map(ContactKeyObject.init)
            .forEach {
                self.pubKeys.append($0)
            }
    }
}

extension ContactObject {
    convenience init(_ contact: Contact) {
        self.init(
            email: contact.email,
            name: contact.name,
            lastUsed: contact.lastUsed,
            keys: contact.pubKeys
        )
    }
}

extension ContactObject: CachedObject {
    // Contacts can be shared between accounts
    // https://github.com/FlowCrypt/flowcrypt-ios/issues/269
    var activeUser: UserObject? { nil }

    var identifier: String { email }
}
