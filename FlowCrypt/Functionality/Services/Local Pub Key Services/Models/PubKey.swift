//
//  ContactKey.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import Foundation

struct PubKey {
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
    /// user emails
    let emails: [String]
}

extension PubKey {
    /// first key longid
    var longid: String? { longids.first }
    /// first key fingerprint
    var fingerprint: String? { fingerprints.first }

    var keyState: PubKeyState {
        guard !isRevoked else { return .revoked }

        guard let expiresOn = expiresOn,
              expiresOn.timeIntervalSinceNow.sign == .minus
        else { return .active }

        return .expired
    }
}

extension PubKey {
    init(keyDetails: KeyDetails) {
        let keyIds = keyDetails.ids
        let longids = keyIds.map(\.longid)
        let fingerprints = keyIds.map(\.fingerprint)

        self.init(armored: keyDetails.public,
                  lastSig: keyDetails.lastModified.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                  lastChecked: Date(),
                  expiresOn: keyDetails.expiration.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                  longids: longids,
                  fingerprints: fingerprints,
                  created: Date(timeIntervalSince1970: Double(keyDetails.created)),
                  algo: keyDetails.algo,
                  isRevoked: keyDetails.revoked,
                  emails: keyDetails.pgpUserEmails)
    }
}

extension PubKey: Equatable {
    static func == (lhs: PubKey, rhs: PubKey) -> Bool {
        lhs.fingerprint == rhs.fingerprint
    }
}
