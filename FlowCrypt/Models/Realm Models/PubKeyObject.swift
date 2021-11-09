//
//  PubKeyObject.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

enum PubKeyObjectError: Error {
    case missingPrimaryFingerprint
}

final class PubKeyObject: Object {
    @Persisted(primaryKey: true) var primaryFingerprint: String = ""
    @Persisted var armored: String = ""
    @Persisted var lastSig: Date?
    @Persisted var lastChecked: Date?
    @Persisted var expiresOn: Date?
    @Persisted var longids: List<String>
    @Persisted var fingerprints: List<String>
    @Persisted var created: Date?

    convenience init(armored: String,
                     lastSig: Date? = nil,
                     lastChecked: Date? = nil,
                     expiresOn: Date? = nil,
                     longids: [String] = [],
                     fingerprints: [String] = [],
                     created: Date? = nil) throws {
        self.init()

        self.armored = armored
        self.lastSig = lastSig
        self.lastChecked = lastChecked
        self.expiresOn = expiresOn
        self.created = created

        self.longids.append(objectsIn: longids)
        self.fingerprints.append(objectsIn: fingerprints)

        guard let primaryFingerprint = self.fingerprints.first else {
            throw PubKeyObjectError.missingPrimaryFingerprint
        }

        self.primaryFingerprint = primaryFingerprint
    }
}

extension PubKeyObject {
    convenience init(_ key: PubKey) throws {
        try self.init(
            armored: key.armored,
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
    func update(from key: PubKey) {
        self.armored = key.armored
        self.lastSig = key.lastSig
        self.lastChecked = key.lastChecked
        self.expiresOn = key.expiresOn
        self.created = key.created

        let longids = List<String>()
        longids.append(objectsIn: key.longids)
        self.longids = longids

        let fingerprints = List<String>()
        fingerprints.append(objectsIn: key.fingerprints)
        self.fingerprints = fingerprints
    }
}
