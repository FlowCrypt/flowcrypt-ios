//
//  Keypair.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 17.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct Keypair {
    var primaryFingerprint: String
    var `private`: String
    var `public`: String
    var passphrase: String?
    var source: String
    var allFingerprints: [String]
    var allLongids: [String]

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
    }
}
