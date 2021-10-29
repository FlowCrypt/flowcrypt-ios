//
//  RecipientObject.swift
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

final class RecipientObject: Object {
    @Persisted(primaryKey: true) var email: String = ""

    @Persisted var name: String?
    @Persisted var lastUsed: Date?
    @Persisted var pubKeys = List<PubKeyObject>()

    convenience init(
        email: String,
        name: String?,
        lastUsed: Date?,
        keys: [PubKey]
    ) {
        self.init()
        self.email = email
        self.name = name ?? ""
        self.lastUsed = lastUsed

        keys
            .compactMap { try? PubKeyObject($0) }
            .forEach { self.pubKeys.append($0) }
    }
}

extension RecipientObject {
    convenience init(_ recipient: RecipientWithSortedPubKeys) {
        self.init(
            email: recipient.email,
            name: recipient.name,
            lastUsed: recipient.lastUsed,
            keys: recipient.pubKeys
        )
    }
}

extension RecipientObject: CachedObject {
    // Contacts can be shared between accounts
    // https://github.com/FlowCrypt/flowcrypt-ios/issues/269
    var activeUser: UserObject? { nil }

    var identifier: String { email }
}
