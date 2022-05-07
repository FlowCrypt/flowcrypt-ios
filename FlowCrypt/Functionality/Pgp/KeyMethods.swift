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
    func filterByPassPhraseMatch<T: ArmoredPrvWithIdentity>(keys: [T], passPhrase: String) async throws -> [T]
    func parseKeys(armored: [String]) async throws -> [KeyDetails]
    func chooseSenderSigningKey(keys: [Keypair], senderEmail: String) async throws -> Keypair?
    func chooseSenderEncryptionKeys(keys: [Keypair], senderEmail: String) async throws -> [Keypair]
}

final class KeyMethods: KeyMethodsType {

    let decrypter: KeyDecrypter

    init(decrypter: KeyDecrypter = Core.shared) {
        self.decrypter = decrypter
    }

    func filterByPassPhraseMatch<T: ArmoredPrvWithIdentity>(keys: [T], passPhrase: String) async throws -> [T] {
        let logger = Logger.nested(in: Self.self, with: .core)
        var matching: [T] = []
        for key in keys {
            guard let privateKey = key.getArmoredPrv() else {
                throw KeypairError.expectedPrivateGotPublic
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
            throw KeypairError.parsingError
        }
        return parsed.keyDetails
    }

    func chooseSenderSigningKey(keys: [Keypair], senderEmail: String) async throws -> Keypair? {
        // TODO - needs to be implemented
        return keys.first
    }

    func chooseSenderEncryptionKeys(keys: [Keypair], senderEmail: String) async throws -> [Keypair] {
        // TODO - needs to be implemented
        return keys
    }
}

//    private func findKeyByUserEmail(keysInfo: [Keypair], email: String) async throws -> Keypair? {
//        logger.logDebug("findKeyByUserEmail: found \(keysInfo.count) candidate prvs in storage, searching by:\(email)")
//        var keys: [(Keypair, KeyDetails)] = []
//        for keyInfo in keysInfo {
//            let parsedKeys = try await core.parseKeys(
//                armoredOrBinary: keyInfo.`private`.data()
//            )
//            guard let parsedKey = parsedKeys.keyDetails.first else {
//                throw KeypairError.parsingError
//            }
//            keys.append((keyInfo, parsedKey))
//        }
//        if let primaryEmailMatch = keys.first(where: {
//            $0.1.pgpUserEmails.first?.lowercased() == email.lowercased() && $0.1.isKeyUsable
//        }) {
//            logger.logDebug("findKeyByUserEmail: found key \(primaryEmailMatch.1.primaryFingerprint) by primary email match")
//            return primaryEmailMatch.0
//        }
//        if let alternativeEmailMatch = keys.first(where: {
//            $0.1.pgpUserEmails.map { $0.lowercased() }.contains(email.lowercased()) == true && $0.1.isKeyUsable
//        }) {
//            logger.logDebug("findKeyByUserEmail: found key \(alternativeEmailMatch.1.primaryFingerprint) by alternative email match")
//            return alternativeEmailMatch.0
//        }
//        logger.logDebug("findKeyByUserEmail: could not match any key")
//        return nil
//    }
