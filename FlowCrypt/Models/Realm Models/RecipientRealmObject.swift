//
//  RecipientRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class RecipientRealmObject: Object {
    @Persisted(primaryKey: true) var email: String
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

        keys
            .compactMap { try? PubKeyRealmObject($0) }
            .forEach { self.pubKeys.append($0) }
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

extension RecipientRealmObject {
    func contains(longid: String) -> Bool {
        pubKeys.first(where: { $0.contains(longid: longid) }) != nil
    }
}
