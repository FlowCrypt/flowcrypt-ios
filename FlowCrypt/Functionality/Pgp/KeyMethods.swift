//
//  KeyMethods.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon

protocol KeyMethodsType {
    func filterByPassPhraseMatch<T: ArmoredPrvWithIdentity>(keys: [T], passPhrase: String) async throws -> [T]
    func parseKeys(armored: [String]) async throws -> [KeyDetails]
    func chooseSenderKeys(for type: KeyUsage, keys: [Keypair], senderEmail: String) async throws -> [Keypair]
}

enum KeyUsage {
    case encryption, signing
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
                try logger.logInfo("pass phrase matches for key: \(key.primaryFingerprint)")
            } catch {
                try logger.logInfo("pass phrase does not match for key: \(key.primaryFingerprint)")
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

    func chooseSenderKeys(for type: KeyUsage, keys: [Keypair], senderEmail: String) async throws -> [Keypair] {
        let armored = try keys.map(type == .encryption ? \.public : \.private)
        let parsed = try await parseKeys(armored: armored)

        guard parsed.isNotEmpty else {
            throw KeypairError.noAccountKeysAvailable
        }

        let usable = parsed.filter(\.isNotExpired).filter {
            type == .encryption ? $0.usableForEncryption : $0.usableForSigning
        }

        let senderEmail = senderEmail.lowercased()

        guard usable.isNotEmpty else {
            if type == .encryption {
                throw MessageValidationError.noUsableAccountKeys
            } else {
                throw ComposeMessageError.noKeysFoundForSign(keys.count, senderEmail)
            }
        }

        if let byPrimaryUid = try filter(keys, usable, ({ $0.pgpUserEmailsLowercased.first == senderEmail })) {
            return byPrimaryUid // if any keys match by primary uid, use them
        }
        if let byAnyUid = try filter(keys, usable, ({ $0.pgpUserEmailsLowercased.contains(senderEmail) })) {
            return byAnyUid // if any keys match by any uid, use them
        }
        // for encryption, even when we cannot find key by the right uid, we can use the keys that don't match uid
        // It won't cause much trouble for encryption, but it does for signature verification,
        // and that's why we're treating them differently. We can be more lenient for encryption.
        if type == .encryption {
            return try filter(keys, usable) ?? [] // use any usable keys
        }
        return []
    }

    private func filter(_ toReturn: [Keypair], _ parsed: [KeyDetails], _ criteria: ((KeyDetails) -> Bool)? = nil) throws -> [Keypair]? {
        let filteredPrimaryFingerprints = try parsed
            .filter { criteria?($0) ?? true }
            .map { try $0.primaryFingerprint }
        let filteredKeypairs = toReturn
            .filter { filteredPrimaryFingerprints.contains($0.primaryFingerprint) }
        guard filteredKeypairs.isNotEmpty else {
            return nil
        }
        return filteredKeypairs
    }
}
