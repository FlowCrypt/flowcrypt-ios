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
    func filterByPassPhraseMatch(keys: [KeyDetails], passPhrase: String) async throws -> [KeyDetails]
    func filterByPassPhraseMatch(keys: [PrvKeyInfo], passPhrase: String) async throws -> [PrvKeyInfo]
    func parseKeys(armored: [String]) async throws -> [KeyDetails]
}

final class KeyMethods: KeyMethodsType {

    let decrypter: KeyDecrypter

    init(decrypter: KeyDecrypter = Core.shared) {
        self.decrypter = decrypter
    }

    // todo - join these two methods into one
    func filterByPassPhraseMatch(keys: [PrvKeyInfo], passPhrase: String) async throws -> [PrvKeyInfo] {
        let logger = Logger.nested(in: Self.self, with: .core)
        var matching: [PrvKeyInfo] = []
        for key in keys {
            do {
                _ = try await self.decrypter.decryptKey(armoredPrv: key.private, passphrase: passPhrase)
                matching.append(key)
                logger.logInfo("pass phrase matches for key: \(key.fingerprints.first ?? "missing fingerprint")")
            } catch {
                logger.logInfo("pass phrase does not match for key: \(key.fingerprints.first ?? "missing fingerprint")")
            }
        }
        return matching
    }

    // todo - join these two methods into one. Maybe drop this one and keep the PrvKeyInfo method?
    func filterByPassPhraseMatch(keys: [KeyDetails], passPhrase: String) async throws -> [KeyDetails] {
        let logger = Logger.nested(in: Self.self, with: .core)
        var matching: [KeyDetails] = []
        for key in keys {
            guard let privateKey = key.private else {
                throw KeyServiceError.expectedPrivateGotPublic
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

    func parseKeys(armored: [String]) async throws -> [KeyDetails] {
        let parsed = try await Core.shared.parseKeys(
            armoredOrBinary: armored.joined(separator: "\n").data()
        )
        guard parsed.keyDetails.count == armored.count else {
            throw KeyServiceError.parsingError
        }
        return parsed.keyDetails
    }
}
