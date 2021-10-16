//
//  ContactKeyObject.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class PubKeyObject: Object {
    @Persisted(primaryKey: true) var key: String = ""

    @Persisted var lastSig: Date?
    @Persisted var lastChecked: Date?
    @Persisted var expiresOn: Date?
    @Persisted var longids: List<String>
    @Persisted var fingerprints: List<String>
    @Persisted var created: Date?

    convenience init(key: String,
                     lastSig: Date? = nil,
                     lastChecked: Date? = nil,
                     expiresOn: Date? = nil,
                     longids: [String] = [],
                     fingerprints: [String] = [],
                     created: Date? = nil) {
        self.init()
        
        self.key = key
        self.lastSig = lastSig
        self.lastChecked = lastChecked
        self.expiresOn = expiresOn
        self.created = created

        longids.forEach { self.longids.append($0) }
        fingerprints.forEach { self.fingerprints.append($0) }
    }
}

extension PubKeyObject {
    convenience init(_ key: PubKey) {
        self.init(
            key: key.key,
            lastSig: key.lastSig,
            lastChecked: key.lastChecked,
            expiresOn: key.expiresOn,
            longids: key.longids,
            fingerprints: key.fingerprints,
            created: key.created
        )
    }
}

extension PubKeyObject {
    var fingerprint: String? { fingerprints.first }
}
