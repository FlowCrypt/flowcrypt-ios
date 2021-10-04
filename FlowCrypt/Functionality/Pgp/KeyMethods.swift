//
//  KeyMethods.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
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

            do {
                _ = try self.decrypter.decryptKey(armoredPrv: privateKey, passphrase: passPhrase)
                return key
            } catch {
                logger.logInfo("Filtered not decrypted key")
                return nil
            }
        }
    }
}
