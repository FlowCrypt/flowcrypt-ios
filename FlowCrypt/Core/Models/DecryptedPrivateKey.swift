//
//  DecryptedPrivateKey.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct DecryptedPrivateKeysResponse: Decodable {
    let privateKeys: [DecryptedPrivateKey]

    struct DecryptedPrivateKey: Decodable {
        let decryptedPrivateKey: String
    }
}
