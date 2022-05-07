//
//  PrvKeyInfo.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct PrvKeyInfo: Encodable, Equatable {
    let `private`: String
    let longid: String
    let passphrase: String?
    let fingerprints: [String]
}

extension PrvKeyInfo {
    init(keypair: Keypair) { // , passphrase: String?
        self.private = keypair.private
        self.longid = keypair.primaryLongid
        self.passphrase = keypair.passphrase // ?? passphrase
        self.fingerprints = keypair.allFingerprints
    }
}

extension PrvKeyInfo {
    var jsonDict: [String: String?] {
        ["private": `private`, "longid": longid, "passphrase": passphrase]
    }

    func copy(with passphrase: String) -> PrvKeyInfo {
        PrvKeyInfo(private: self.private,
                   longid: self.longid,
                   passphrase: self.passphrase ?? passphrase,
                   fingerprints: self.fingerprints)
    }
}
