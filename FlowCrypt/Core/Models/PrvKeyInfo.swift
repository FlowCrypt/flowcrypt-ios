//
//  PrvKeyInfo.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct PrvKeyInfo: Encodable {
    let `private`: String
    let longid: String
    let passphrase: String?
}

// TODO: - ANTON
//extension PrvKeyInfo {
//    init(from keyInfo: KeyInfo) {
//        self.private = keyInfo.private
//        self.longid = keyInfo.longid
//        self.passphrase = keyInfo.passphrase
//    }
//}
