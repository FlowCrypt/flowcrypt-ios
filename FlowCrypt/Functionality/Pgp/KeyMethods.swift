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
    func filterByPassPhraseMatch(keys: [PrvKeyInfo], passPhrase: String) -> [PrvKeyInfo]
}

final class KeyMethods: KeyMethodsType {

    let decrypter: KeyDecrypter

    init(decrypter: KeyDecrypter = Core.shared) {
        self.decrypter = decrypter
    }

    // todo - join these two methods into one
    func filterByPassPhraseMatch(keys: [PrvKeyInfo], passPhrase: String) -> [PrvKeyInfo] {
        let logger = Logger.nested(in: Self.self, with: .core)
        return keys.compactMap { key -> PrvKeyInfo? in
            do {
                _ = try self.decrypter.decryptKey(armoredPrv: key.private, passphrase: passPhrase)
                return key
            } catch {
                logger.logInfo("pass phrase does not match for key: \(key.fingerprints.first ?? "missing fingerprint")")
                return nil
            }
        }
    }

    // todo - join these two methods into one. Maybe drop this one and keep the PrvKeyInfo method?
    func filterByPassPhraseMatch(keys: [KeyDetails], passPhrase: String) async throws -> [KeyDetails] {
        let logger = Logger.nested(in: Self.self, with: .core)
        var matching: [KeyDetails] = []
        for key in keys {
            guard let privateKey = key.private else {
                throw AppErr.general("unexpectedly received public key: \(key.primaryFingerprint)")
            }
            do {
                _ = try await self.decrypter.decryptKey(armoredPrv: privateKey, passphrase: passPhrase)
                matching.append(key)
                logger.logInfo("pass phrase matches for key: \(key.primaryFingerprint)")
            } catch {
                logger.logInfo("pass phrase does not match for key: \(key.primaryFingerprint)")
            }
        }
        return matching
    }
}
