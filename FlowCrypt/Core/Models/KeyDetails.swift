//
//  KeyDetails.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import MailCore

protocol ArmoredPrvWithIdentity {
    var primaryFingerprint: String { get throws }
    func getArmoredPrv() -> String?
}

struct KeyDetails: ArmoredPrvWithIdentity, Decodable {
    let `public`: String
    let `private`: String? // only if this is prv
    let isFullyDecrypted: Bool? // only if this is prv
    let isFullyEncrypted: Bool? // only if this is prv
    let usableForEncryption: Bool
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
        get throws {
            guard let fingerPrint = fingerprints.first else {
                throw AppErr.general("primaryFingerprint for KeyDetail is missing")
            }
            return fingerPrint
        }
    }

    var pgpUserEmails: [String] {
        users.map { MCOAddress(nonEncodedRFC822String: $0).mailbox }
    }

    var pgpUserEmailsLowercased: [String] {
        pgpUserEmails.map { $0.lowercased() }
    }

    var isNotExpired: Bool {
        guard let expiration else { return true }
        return expiration.toDate().timeIntervalSinceNow > 0
    }

    func getArmoredPrv() -> String? {
        return `private`
    }
}

// MARK: - CustomStringConvertible, Hashable, Equatable
extension KeyDetails: CustomStringConvertible {
    var description: String {
        "public = \(`public`) ### ids = \(ids) ### users = \(users) ### algo = \(algo.debugDescription)"
    }
}

// MARK: - Other
extension [KeyDetails] {
    // concatenated private keys, joined with a newline
    var joinedPrivateKey: String {
        compactMap(\.private).joined(separator: "\n")
    }

    func getUniqueByFingerprintByPreferingLatestLastModified() -> [KeyDetails] {
        var uniqueKeyDetails: [KeyDetails] = []
        for keyDetail in self {
            if let keyIndex = uniqueKeyDetails.firstIndex(where: { $0.fingerprints == keyDetail.fingerprints }) {
                if uniqueKeyDetails[keyIndex].lastModified ?? 0 < keyDetail.lastModified ?? 0 {
                    uniqueKeyDetails[keyIndex] = keyDetail
                }
            } else {
                uniqueKeyDetails.append(keyDetail)
            }
        }
        return uniqueKeyDetails
    }
}
