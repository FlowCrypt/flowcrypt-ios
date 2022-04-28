//
//  KeyDetails.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import MailCore
import Foundation

struct KeyDetails: Decodable {
    let `public`: String
    let `private`: String? // ony if this is prv
    let isFullyDecrypted: Bool? // only if this is prv
    let isFullyEncrypted: Bool? // only if this is prv
    let ids: [KeyId]
    let created: Int
    let lastModified: Int?
    let expiration: Int?
    let users: [String]
    let algo: KeyAlgo?
    let revoked: Bool
}

// MARK: - Convenience
extension KeyDetails {
    var fingerprints: [String] {
        ids.map(\.fingerprint)
    }

    var primaryFingerprint: String {
        guard let fingerPrint = fingerprints.first else {
            fatalError("primaryFingerprint for KeyDetail is missing")
        }
        return fingerPrint
    }

    var pgpUserEmails: [String] {
        users.map { MCOAddress(nonEncodedRFC822String: $0).mailbox }
    }
    
    var isKeyUsuable: Bool {
        var expired = false
        let now = Date()
        if let expiration = expiration, TimeInterval(expiration) < now.timeIntervalSince1970 {
            expired = true
        }
        return !revoked && !expired
    }
}

// MARK: - CustomStringConvertible, Hashable, Equatable
extension KeyDetails: CustomStringConvertible, Hashable, Equatable {
    var description: String {
        "public = \(`public`) ### ids = \(ids) ### users = \(users) ### algo = \(algo.debugDescription)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.ids.first)
    }

    static func == (lhs: KeyDetails, rhs: KeyDetails) -> Bool {
        lhs.ids == rhs.ids
    }
}

// MARK: - Other
extension Array where Element == KeyDetails {
    // concatenated private keys, joined with a newline
    var joinedPrivateKey: String {
        compactMap(\.private).joined(separator: "\n")
    }
}
