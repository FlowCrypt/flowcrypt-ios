//
//  Keypair.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 17.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct Keypair: ArmoredPrvWithIdentity, Equatable {
    var primaryFingerprint: String
    var `private`: String
    var `public`: String
    var passphrase: String?
    var source: String
    var allFingerprints: [String]
    var allLongids: [String]
    var lastModified: Int

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
        self.allFingerprints = object.allFingerprints.map { $0 }
        self.allLongids = object.allLongids.map { $0 }
        self.lastModified = object.lastModified
    }

    init (_ k: KeyDetails, passPhrase: String?, source: String) throws {
        // todo - this is duplicate code from KeypairRealmObject
        guard let privateKey = k.private, let isFullyEncrypted = k.isFullyEncrypted else {
            throw KeypairError.missingPrivateKey("storing pubkey as private")
        }
        guard isFullyEncrypted else {
            throw KeypairError.notEncrypted("Will not store Private Key that is not fully encrypted")
        }
        guard k.ids.isNotEmpty else {
            throw KeypairError.missingKeyIds
        }
        // end duplicate
        self.primaryFingerprint = k.primaryFingerprint
        self.private = privateKey
        self.public = k.public
        self.passphrase = passPhrase
        self.source = source
        self.allFingerprints = k.fingerprints
        self.allLongids = k.ids.map { $0.longid }
        guard let lastModified = k.lastModified else {
            // todo - make a new error like `keyMissingSelfSignature`
            throw KeyMethodsError.parsingError
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
