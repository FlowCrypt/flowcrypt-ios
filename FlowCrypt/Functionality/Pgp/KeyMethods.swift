//
//  KeyMethods.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeyMethodsType {
    func filterByPassPhraseMatch(keys: [KeyDetails], passPhrase: String) -> [KeyDetails]
}

struct KeyMethods: KeyMethodsType {
    let core: Core

    func filterByPassPhraseMatch(keys: [KeyDetails], passPhrase: String) -> [KeyDetails] {
        keys.compactMap { key -> KeyDetails? in
            guard let privateKey = key.private,
                  let decrypted = try? self.core.decryptKey(armoredPrv: privateKey, passphrase: passPhrase),
                  decrypted.decryptedKey != nil
            else { return nil }
            return key
        }
    }
}
