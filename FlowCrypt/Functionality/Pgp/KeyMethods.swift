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

    func filterByPassPhraseMatch<T: ArmoredPrvWithIdentity>(keys: [T], passPhrase: String) async throws -> [T] {
        let logger = Logger.nested(in: Self.self, with: .core)
        var matching: [T] = []
        for key in keys {
            guard let privateKey = key.getArmoredPrv() else {
                throw KeypairError.expectedPrivateGotPublic
            }
            do {
                _ = try await Core.shared.decryptKey(armoredPrv: privateKey, passphrase: passPhrase)
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
        let parsed = try await parseKeys(armored: keys.map { $0.private })
        guard let usable = parsed.first(where: { $0.isKeyUsable }) else { return nil }
        return keys.first { $0.primaryFingerprint == usable.primaryFingerprint }
    }

    func chooseSenderEncryptionKeys(keys: [Keypair], senderEmail: String) async throws -> [Keypair] {
        let senderEmail = senderEmail.lowercased()
        let parsed = try await parseKeys(armored: keys.map { $0.public })
        guard parsed.isNotEmpty else {
            throw KeypairError.noAccountKeysAvailable
        }
        let usable = parsed.filter { $0.isKeyUsable }
        guard usable.isNotEmpty else {
            throw MessageValidationError.noUsableAccountKeys
        }
        if let byPrimaryUid = filter(keys, usable, ({ $0.pgpUserEmailsLowercased.first == senderEmail })) {
            return byPrimaryUid // if any keys match by primary uid, use them
        }
        if let byAnyUid = filter(keys, usable, ({ $0.pgpUserEmailsLowercased.contains(senderEmail) })) {
            return byAnyUid // if any keys match by any uid, use them
        }
        return filter(keys, usable, { _ in true }) ?? [] // use any usable keys
    }

    private func filter(_ toReturn: [Keypair], _ parsed: [KeyDetails], _ criteria: (KeyDetails) -> Bool) -> [Keypair]? {
        let filteredPrimaryFingerprints = parsed
            .filter { criteria($0) }
            .map { $0.primaryFingerprint }
        let filteredKeypairs = toReturn
            .filter { filteredPrimaryFingerprints.contains($0.primaryFingerprint) }
        guard filteredKeypairs.isNotEmpty else {
            return nil
        }
        return filteredKeypairs
    }
}
