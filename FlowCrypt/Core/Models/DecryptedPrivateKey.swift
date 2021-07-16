//
//  DecryptedPrivateKey.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct DecryptedPrivateKeysContainer: Decodable {

    let privateKeys: [DecryptedPrivateKey]
}

struct DecryptedPrivateKey: Decodable {

    let decryptedPrivateKey: String
}
