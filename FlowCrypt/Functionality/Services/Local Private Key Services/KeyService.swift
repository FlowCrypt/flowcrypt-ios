//
//  KeyService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import FlowCryptCommon

protocol KeyServiceType {
    func getPrvKeyInfo(email: String) async throws -> [PrvKeyInfo]
    func getSigningKey(email: String) async throws -> PrvKeyInfo?
    func getKeyPair(from email: String) async throws -> Keypair?
}

final class KeyService: KeyServiceType {

    let core: Core = .shared
    let storage: EncryptedStorageType
    let passPhraseService: PassPhraseServiceType
    let logger: Logger

    init(
        storage: EncryptedStorageType,
        passPhraseService: PassPhraseServiceType
    ) {
        self.storage = storage
        self.passPhraseService = passPhraseService
        self.logger = Logger.nested(in: Self.self, with: "KeyService")
    }

    /// Use to get list of PrvKeyInfo
    func getPrvKeyInfo(email: String) async throws -> [PrvKeyInfo] {
        let privateKeys = try storage.getKeypairs(by: email)
            .map { keypair -> PrvKeyInfo in
                return try self.getPrvKeyInfo(keyPair: keypair)
            }
        return privateKeys
    }

    func getSigningKey(email: String) async throws -> PrvKeyInfo? {
        guard let foundKey = try await getKeyPair(from: email) else {
            return nil
        }

        return try self.getPrvKeyInfo(keyPair: foundKey)
    }

    func getKeyPair(from email: String) async throws -> Keypair? {
        let keysInfo = try storage.getKeypairs(by: email)
        return try await findKeyByUserEmail(keysInfo: keysInfo, email: email)
    }

    // Get Private Key Info from KeyPair
    private func getPrvKeyInfo(keyPair: Keypair) throws -> PrvKeyInfo {
        let storedPassPhrases = try passPhraseService.getPassPhrases()
        let passphrase = storedPassPhrases
            .filter { $0.value.isNotEmpty }
            .first(where: { $0.primaryFingerprintOfAssociatedKey == keyPair.primaryFingerprint })?
            .value
        return PrvKeyInfo(keypair: keyPair, passphrase: passphrase)
    }

    private func findKeyByUserEmail(keysInfo: [Keypair], email: String) async throws -> Keypair? {
        // todo - should be refactored with https://github.com/FlowCrypt/flowcrypt-ios/issues/812
        logger.logDebug("findKeyByUserEmail: found \(keysInfo.count) candidate prvs in storage, searching by:\(email)")
        var keys: [(Keypair, KeyDetails)] = []
        for keyInfo in keysInfo {
            let parsedKeys = try await core.parseKeys(
                armoredOrBinary: keyInfo.`private`.data()
            )
            guard let parsedKey = parsedKeys.keyDetails.first else {
                throw KeyServiceError.parsingError
            }
            keys.append((keyInfo, parsedKey))
        }
        if let primaryEmailMatch = keys.first(where: {
            $0.1.pgpUserEmails.first?.lowercased() == email.lowercased() && $0.1.isKeyUsuable
        }) {
            logger.logDebug("findKeyByUserEmail: found key \(primaryEmailMatch.1.primaryFingerprint) by primary email match")
            return primaryEmailMatch.0
        }
        if let alternativeEmailMatch = keys.first(where: {
            $0.1.pgpUserEmails.map { $0.lowercased() }.contains(email.lowercased()) == true && $0.1.isKeyUsuable
        }) {
            logger.logDebug("findKeyByUserEmail: found key \(alternativeEmailMatch.1.primaryFingerprint) by alternative email match")
            return alternativeEmailMatch.0
        }
        logger.logDebug("findKeyByUserEmail: could not match any key")
        return nil
    }
}
