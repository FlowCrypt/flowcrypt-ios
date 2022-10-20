//
//  Keypair.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 17.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum KeypairError: Error, Equatable {
    case missingPrivateKey(String)
    case notEncrypted(String)
    case missingKeyIds
    case missingPrimaryFingerprint
    case parsingError
    case keyMissingSelfSignature
    case noAccountKeysAvailable
    case expectedPrivateGotPublic
}

extension KeypairError: CustomStringConvertible {

    var description: String {
        switch self {
        case .parsingError:
            return "KeypairError_parsing_error".localized
        case .noAccountKeysAvailable:
            return "KeypairError_no_account_keys_available_error".localized
        case .expectedPrivateGotPublic:
            return "KeypairError_expected_public_got_private".localized
        default:
            return localizedDescription
        }
    }
}

struct Keypair: ArmoredPrvWithIdentity, Equatable {
    var primaryFingerprint: String
    var `private`: String
    var `public`: String
    var passphrase: String?
    var source: String
    var allFingerprints: [String]
    var allLongids: [String]
    var lastModified: Int
    var isRevoked: Bool

    var primaryLongid: String {
        allLongids[0]
    }
}

extension Keypair {
    init(_ object: KeypairRealmObject) {
        self.primaryFingerprint = object.primaryFingerprint
        self.private = object.private
        self.public = object.public
        self.passphrase = object.passphrase
        self.source = object.source
        self.allFingerprints = Array(object.allFingerprints)
        self.allLongids = Array(object.allLongids)
        self.lastModified = object.lastModified
        self.isRevoked = object.isRevoked
    }

    init(_ k: KeyDetails, passPhrase: String?, source: String) throws {
        guard let privateKey = k.private, let isFullyEncrypted = k.isFullyEncrypted else {
            throw KeypairError.missingPrivateKey("storing pubkey as private")
        }
        guard isFullyEncrypted else {
            throw KeypairError.notEncrypted("Will not store Private Key that is not fully encrypted")
        }
        guard k.ids.isNotEmpty else {
            throw KeypairError.missingKeyIds
        }
        guard let primaryFingerprint = k.ids.first?.fingerprint else {
            throw KeypairError.missingPrimaryFingerprint
        }
        self.primaryFingerprint = primaryFingerprint
        self.private = privateKey
        self.public = k.public
        self.passphrase = passPhrase
        self.source = source
        self.allFingerprints = k.fingerprints
        self.allLongids = k.ids.map(\.longid)
        self.isRevoked = k.revoked
        guard let lastModified = k.lastModified else {
            throw KeypairError.keyMissingSelfSignature
        }
        self.lastModified = lastModified
    }

    func getArmoredPrv() -> String? {
        return `private`
    }

    var prvKeyInfoJsonDictForCore: [String: String?] {
        // this exact format is needed by Core javascript code
        ["private": `private`, "longid": primaryLongid, "passphrase": passphrase]
    }
}
