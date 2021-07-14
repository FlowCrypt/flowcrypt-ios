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

final class KeyMethods: KeyMethodsType {

    let decrypter: KeyDecrypter

    init(decrypter: KeyDecrypter = Core.shared) {
        self.decrypter = decrypter
    }

    func filterByPassPhraseMatch(keys: [KeyDetails], passPhrase: String) -> [KeyDetails] {
        let logger = Logger.nested(in: Self.self, with: .core)

        guard keys.isNotEmpty else {
            logger.logInfo("Keys are empty")
            return []
        }

        return keys.compactMap { key -> KeyDetails? in
            guard let privateKey = key.private else {
                logger.logInfo("Filtered not private key")
                return nil
            }

            guard let decrypted = try? self.decrypter.decryptKey(armoredPrv: privateKey, passphrase: passPhrase) else {
                logger.logInfo("Filtered not decrypted key")
                return nil
            }

            // TODO: - ANTON - longid
            guard decrypted.decryptedKey != nil else {
                logger.logInfo("Filtered. decryptedKey = nil for key \(key.longid)")
                return nil
            }

            return key
        }
    }
}
