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
    func getPrvKeyDetails() -> Result<[KeyDetails], KeyServiceError>
    func getPrvKeyInfo() -> Result<[PrvKeyInfo], KeyServiceError>
    func getSigningKey() throws -> PrvKeyInfo?
}

enum KeyServiceError: Error {
    case unexpected, parsingError, retrieve
}

final class KeyService: KeyServiceType {
    let coreService: Core = .shared
    let storage: KeyStorageType
    let passPhraseService: PassPhraseServiceType
    let currentUserEmail: () -> (String?)
    let logger: Logger

    init(
        storage: KeyStorageType = KeyDataStorage(),
        passPhraseService: PassPhraseServiceType = PassPhraseService(),
        currentUserEmail: @autoclosure @escaping () -> (String?) = DataService.shared.email
    ) {
        self.storage = storage
        self.passPhraseService = passPhraseService
        self.currentUserEmail = currentUserEmail
        self.logger = Logger.nested(in: Self.self, with: "KeyService")
    }

    /// Use to get list of keys (including missing pass phrases keys)
    func getPrvKeyDetails() -> Result<[KeyDetails], KeyServiceError> {
        guard let email = currentUserEmail() else {
            return .failure(.retrieve)
        }

        let privateKeys = storage.keysInfo()
            .filter { $0.account == email }
            .map(\.private)

        let keyDetails = privateKeys
            .compactMap {
                try? coreService.parseKeys(armoredOrBinary: $0.data())
            }
            .map(\.keyDetails)
            .flatMap { $0 }

        guard keyDetails.count == privateKeys.count else {
            return .failure(.parsingError)
        }

        return .success(keyDetails)
    }

    /// Use to get list of PrvKeyInfo
    func getPrvKeyInfo() -> Result<[PrvKeyInfo], KeyServiceError> {
        guard let email = currentUserEmail() else {
            return .failure(.retrieve)
        }

        let keysInfo = storage.keysInfo()
            .filter { $0.account == email }

        let storedPassPhrases = passPhraseService.getPassPhrases()

        let privateKeys = keysInfo
            .map { keyInfo -> PrvKeyInfo in
                let passphrase = storedPassPhrases
                    .filter { $0.value.isNotEmpty }
                    .first(where: { $0.primaryFingerprintOfAssociatedKey == keyInfo.primaryFingerprint })?
                    .value

                return PrvKeyInfo(keyInfo: keyInfo, passphrase: passphrase)
            }

        return .success(privateKeys)
    }

    func getSigningKey() throws -> PrvKeyInfo? {
        guard let email = currentUserEmail() else {
            logger.logError("no current user email")
            throw AppErr.noCurrentUser
        }
        // get keys associated with this account
        let keysInfo = storage.keysInfo().filter { $0.account == email }
        guard let foundKey = try findKeyByUserEmail(keysInfo: keysInfo, email: email) else {
            return nil
        }

        let storedPassPhrases = passPhraseService.getPassPhrases()
        let passphrase = storedPassPhrases
            .filter { $0.value.isNotEmpty }
            .first(where: { $0.primaryFingerprintOfAssociatedKey == foundKey.primaryFingerprint })?
            .value

        return PrvKeyInfo(keyInfo: foundKey, passphrase: passphrase)
    }

    private func findKeyByUserEmail(keysInfo: [KeyInfo], email: String) throws -> KeyInfo? {
        // todo - should be refactored with https://github.com/FlowCrypt/flowcrypt-ios/issues/812
        logger.logDebug("findKeyByUserEmail: found \(keysInfo.count) candidate prvs in storage, searching by:\(email)")
        let keys: [(KeyInfo, KeyDetails?)] = try keysInfo.map {
            let parsedKeys = try self.coreService.parseKeys(
                armoredOrBinary: $0.`private`.data()
            )
            let parsedKey = parsedKeys.keyDetails.first
            logger.logDebug("findKeyByUserEmail: PrvKeyInfo from storage has primary fingerprint \($0.primaryFingerprint) vs parsed key \(parsedKey?.primaryFingerprint ?? "NIL") and has emails \(parsedKey?.pgpUserEmails)")
            return ($0, parsedKey)
        }

        if let primaryEmailMatch = keys.first(where: { $0.1?.pgpUserEmails.first?.lowercased() == email.lowercased() }) {
            logger.logDebug("findKeyByUserEmail: found key \(primaryEmailMatch.1?.primaryFingerprint ?? "NIL") by primary email match")
            return primaryEmailMatch.0
        }

        if let alternativeEmailMatch = keys.first(where: { $0.1?.pgpUserEmails.map { $0.lowercased() }.contains(email.lowercased()) == true }) {
            logger.logDebug("findKeyByUserEmail: found key \(alternativeEmailMatch.1?.primaryFingerprint ?? "NIL") by alternative email match")
            return alternativeEmailMatch.0
        }
        logger.logDebug("findKeyByUserEmail: could not match any key")
        return nil
    }
}
