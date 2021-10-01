//
//  PrvKeyInfo.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct PrvKeyInfo: Encodable {
    let `private`: String
    let longid: String
    let passphrase: String?
    let fingerprints: [String]
}

extension PrvKeyInfo {
    init(keyInfo: KeyInfo, passphrase: String?) {
        self.private = keyInfo.private
        self.longid = keyInfo.primaryLongid
        self.passphrase = passphrase // TODO: Add check for keyInfo passphrase
        self.fingerprints = Array(keyInfo.allFingerprints)
    }
}
