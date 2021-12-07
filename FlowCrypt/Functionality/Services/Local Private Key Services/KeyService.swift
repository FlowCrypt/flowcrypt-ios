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
    func getPrvKeyDetails() async throws -> [KeyDetails]
    func getPrvKeyInfo() async throws -> [PrvKeyInfo]
    func getSigningKey() async throws -> PrvKeyInfo?
}

enum KeyServiceError: Error {
    case unexpected, parsingError, retrieve, missingCurrentUserEmail, expectedPrivateGotPublic
}

final class KeyService: KeyServiceType {

    let coreService: Core = .shared
    let storage: EncryptedStorageType
    let passPhraseService: PassPhraseServiceType
    let currentUserEmail: () -> (String?)
    let logger: Logger

    init(
        storage: EncryptedStorageType,
        passPhraseService: PassPhraseServiceType,
        currentUserEmail: @escaping () -> (String?)
    ) {
        self.storage = storage
        self.passPhraseService = passPhraseService
        self.currentUserEmail = currentUserEmail
        self.logger = Logger.nested(in: Self.self, with: "KeyService")
    }

    /// Use to get list of keys (including missing pass phrases keys)
    func getPrvKeyDetails() async throws -> [KeyDetails] {
        guard let email = currentUserEmail() else {
            throw KeyServiceError.missingCurrentUserEmail
        }
        let privateKeys = storage.getKeypairs(by: email).map(\.private)
        let parsed = try await coreService.parseKeys(
            armoredOrBinary: privateKeys.joined(separator: "\n").data()
        )
        guard parsed.keyDetails.count == privateKeys.count else {
            throw KeyServiceError.parsingError
        }
        return parsed.keyDetails
    }

    /// Use to get list of PrvKeyInfo
    func getPrvKeyInfo() async throws -> [PrvKeyInfo] {
        guard let email = currentUserEmail() else {
            throw KeyServiceError.missingCurrentUserEmail
        }

        let storedPassPhrases = passPhraseService.getPassPhrases()
        let privateKeys = storage.getKeypairs(by: email)
            .map { keypair -> PrvKeyInfo in
                let passphrase = storedPassPhrases
                    .filter { $0.value.isNotEmpty }
                    .first(where: { $0.primaryFingerprintOfAssociatedKey == keypair.primaryFingerprint })?
                    .value
                return PrvKeyInfo(keypair: keypair, passphrase: passphrase)
            }
        return privateKeys
    }

    func getSigningKey() async throws -> PrvKeyInfo? {
        guard let email = currentUserEmail() else {
            logger.logError("no current user email")
            throw AppErr.noCurrentUser
        }

        let keysInfo = storage.getKeypairs(by: email)
        guard let foundKey = try await findKeyByUserEmail(keysInfo: keysInfo, email: email) else {
            return nil
        }

        let storedPassPhrases = passPhraseService.getPassPhrases()
        let passphrase = storedPassPhrases
            .filter { $0.value.isNotEmpty }
            .first(where: { $0.primaryFingerprintOfAssociatedKey == foundKey.primaryFingerprint })?
            .value

        return PrvKeyInfo(keypair: foundKey, passphrase: passphrase)
    }

    private func findKeyByUserEmail(keysInfo: [Keypair], email: String) async throws -> Keypair? {
        // todo - should be refactored with https://github.com/FlowCrypt/flowcrypt-ios/issues/812
        logger.logDebug("findKeyByUserEmail: found \(keysInfo.count) candidate prvs in storage, searching by:\(email)")
        var keys: [(Keypair, KeyDetails)] = []
        for keyInfo in keysInfo {
            let parsedKeys = try await coreService.parseKeys(
                armoredOrBinary: keyInfo.`private`.data()
            )
            guard let parsedKey = parsedKeys.keyDetails.first else {
                throw KeyServiceError.parsingError
            }
//            logger.logDebug("findKeyByUserEmail: PrvKeyInfo from storage has primary fingerprint \(keyInfo.primaryFingerprint) vs parsed key \(parsedKey.primaryFingerprint) and has emails \(parsedKey.pgpUserEmails)")
            keys.append((keyInfo, parsedKey))
        }
        if let primaryEmailMatch = keys.first(where: { $0.1.pgpUserEmails.first?.lowercased() == email.lowercased() }) {
            logger.logDebug("findKeyByUserEmail: found key \(primaryEmailMatch.1.primaryFingerprint) by primary email match")
            return primaryEmailMatch.0
        }
        if let alternativeEmailMatch = keys.first(where: { $0.1.pgpUserEmails.map { $0.lowercased() }.contains(email.lowercased()) == true }) {
            logger.logDebug("findKeyByUserEmail: found key \(alternativeEmailMatch.1.primaryFingerprint) by alternative email match")
            return alternativeEmailMatch.0
        }
        logger.logDebug("findKeyByUserEmail: could not match any key")
        return nil
    }
}
