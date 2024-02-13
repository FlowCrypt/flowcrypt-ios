//
//  PubKey.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct PubKey {
    let primaryFingerprint: String
    let armored: String
    /// will be provided later
    let lastSig: Date?
    /// the date when key was retrieved from a public key server, or nil
    let lastChecked: Date?
    /// expiration date
    let expiresOn: Date?
    /// all key longids
    let longids: [String]
    /// all key fingerprints
    let fingerprints: [String]
    /// key created date
    let created: Date?
    /// key algo
    let algo: KeyAlgo?
    /// is key revoked
    let isRevoked: Bool
    /// key usable for encryption
    let usableForEncryption: Bool
    /// key usable for signing
    let usableForSigning: Bool
    /// user emails
    let emails: [String]
}

extension PubKey {
    /// first key longid
    var longid: String? { longids.first }
    /// first key fingerprint
    var fingerprint: String? { fingerprints.first }

    var keyState: PubKeyState {
        if isRevoked {
            return .revoked
        }
        if !usableForEncryption {
            return .notUsableForEncryption
        }
        if !usableForSigning {
            return .notUsableForSigning
        }
        guard let expiresOn,
              expiresOn.timeIntervalSinceNow.sign == .minus
        else { return .active }

        return .expired
    }
}

extension PubKey {
    init(keyDetails: KeyDetails) throws {
        let keyIds = keyDetails.ids
        let longids = keyIds.map(\.longid)
        let fingerprints = keyIds.map(\.fingerprint)

        try self.init(
            primaryFingerprint: keyDetails.primaryFingerprint,
            armored: keyDetails.public,
            lastSig: keyDetails.lastModified.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            lastChecked: Date(),
            expiresOn: keyDetails.expiration.ifNotNil { Date(timeIntervalSince1970: TimeInterval($0)) },
            longids: longids,
            fingerprints: fingerprints,
            created: Date(timeIntervalSince1970: Double(keyDetails.created)),
            algo: keyDetails.algo,
            isRevoked: keyDetails.revoked,
            usableForEncryption: keyDetails.usableForEncryption,
            usableForSigning: keyDetails.usableForSigning,
            emails: keyDetails.pgpUserEmails
        )
    }
}

extension PubKey {
    init(_ object: PubKeyRealmObject) {
        self.primaryFingerprint = object.primaryFingerprint
        self.armored = object.armored
        self.lastSig = object.lastSig
        self.lastChecked = object.lastChecked
        self.expiresOn = object.expiresOn
        self.longids = Array(object.longids)
        self.fingerprints = Array(object.fingerprints)
        self.created = object.created

        self.algo = nil
        self.isRevoked = object.isRevoked
        self.usableForEncryption = object.usableForEncryption
        self.usableForSigning = object.usableForSigning
        self.emails = []
    }
}

extension PubKey: Equatable {
    static func == (lhs: PubKey, rhs: PubKey) -> Bool {
        lhs.fingerprint == rhs.fingerprint
    }
}
