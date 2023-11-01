//
//  PubKeyRealmObject.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

enum PubKeyObjectError: Error {
    case missingPrimaryFingerprint
}

final class PubKeyRealmObject: Object {
    @Persisted(primaryKey: true) var primaryFingerprint: String
    @Persisted var armored: String
    @Persisted var lastSig: Date?
    @Persisted var lastChecked: Date?
    @Persisted var expiresOn: Date?
    @Persisted var longids: List<String>
    @Persisted var fingerprints: List<String>
    @Persisted var created: Date?
    @Persisted var isRevoked = false
    @Persisted var usableForEncryption = false
    @Persisted var usableForSigning = false
}

extension PubKeyRealmObject {
    convenience init(armored: String,
                     lastSig: Date? = nil,
                     lastChecked: Date? = nil,
                     expiresOn: Date? = nil,
                     longids: [String] = [],
                     fingerprints: [String] = [],
                     created: Date? = nil,
                     isRevoked: Bool,
                     usableForEncryption: Bool,
                     usableForSigning: Bool) throws {
        self.init()

        self.armored = armored
        self.lastSig = lastSig
        self.lastChecked = lastChecked
        self.expiresOn = expiresOn
        self.created = created
        self.isRevoked = isRevoked
        self.usableForEncryption = usableForEncryption
        self.usableForSigning = usableForSigning

        self.longids.append(objectsIn: longids)
        self.fingerprints.append(objectsIn: fingerprints)

        guard let primaryFingerprint = self.fingerprints.first else {
            throw PubKeyObjectError.missingPrimaryFingerprint
        }

        self.primaryFingerprint = primaryFingerprint
    }
}

extension PubKeyRealmObject {
    convenience init(_ key: PubKey) throws {
        try self.init(
            armored: key.armored,
            lastSig: key.lastSig,
            lastChecked: key.lastChecked,
            expiresOn: key.expiresOn,
            longids: key.longids,
            fingerprints: key.fingerprints,
            created: key.created,
            isRevoked: key.isRevoked,
            usableForEncryption: key.usableForEncryption,
            usableForSigning: key.usableForSigning
        )
    }
}

extension PubKeyRealmObject {
    func update(from key: PubKey) {
        self.armored = key.armored
        self.lastSig = key.lastSig
        self.lastChecked = key.lastChecked
        self.expiresOn = key.expiresOn
        self.created = key.created
        self.isRevoked = key.isRevoked
        self.usableForEncryption = key.usableForEncryption
        self.usableForSigning = key.usableForSigning

        let longids = List<String>()
        longids.append(objectsIn: key.longids)
        self.longids = longids

        let fingerprints = List<String>()
        fingerprints.append(objectsIn: key.fingerprints)
        self.fingerprints = fingerprints
    }
}
