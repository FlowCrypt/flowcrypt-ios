//
//  ContactKey.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import Foundation

struct ContactKey {
    let key: String
    /// will be provided later
    let lastSig: Date?
    /// the date when key was retrieved from Attester, or nil
    let lastChecked: Date?
    /// expiration date
    let expiresOn: Date?
    /// all key longids, comma-separated
    let longids: [String]
    /// all key fingerprints, comma-separated
    let fingerprints: [String]
    /// key created date
    let created: Date?
    /// key algo
    let algo: KeyAlgo?
}

extension ContactKey {
    /// first key longid
    var longid: String? { longids.first }
    /// first key fingerprint
    var fingerprint: String? { fingerprints.first }
}

extension ContactKey {
    init(keyDetails: KeyDetails) {
        let keyIds = keyDetails.ids
        let longids = keyIds.map(\.longid)
        let fingerprints = keyIds.map(\.fingerprint)

        self.init(key: keyDetails.public,
                  lastSig: keyDetails.lastModified.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                  lastChecked: Date(),
                  expiresOn: keyDetails.expiration.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                  longids: longids,
                  fingerprints: fingerprints,
                  created: Date(timeIntervalSince1970: Double(keyDetails.created)),
                  algo: keyDetails.algo)
    }
}
