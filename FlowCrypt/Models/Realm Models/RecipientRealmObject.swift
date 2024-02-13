//
//  RecipientRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

final class RecipientRealmObject: Object {
    @Persisted(primaryKey: true) var email: String // swiftlint:disable:this attributes
    @Persisted var name: String?
    @Persisted var lastUsed: Date?
    @Persisted var pubKeys: List<PubKeyRealmObject>
}

extension RecipientRealmObject {
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

        let realmKeys = keys
            .compactMap { try? PubKeyRealmObject($0) }
        for realmKey in realmKeys {
            self.pubKeys.append(realmKey)
        }
    }
}

extension RecipientRealmObject {
    convenience init(_ recipient: RecipientWithSortedPubKeys) {
        self.init(
            email: recipient.email,
            name: recipient.name,
            lastUsed: recipient.lastUsed,
            keys: recipient.pubKeys
        )
    }
}
