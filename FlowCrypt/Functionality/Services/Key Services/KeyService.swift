//
//  KeyService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

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

    init(
        storage: KeyStorageType = KeyDataStorage(),
        passPhraseService: PassPhraseServiceType = PassPhraseService(),
        currentUserEmail: @autoclosure @escaping () -> (String?) = DataService.shared.email
    ) {
        self.storage = storage
        self.passPhraseService = passPhraseService
        self.currentUserEmail = currentUserEmail
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
                    .first(where: { $0.primaryFingerprint == keyInfo.primaryFingerprint })?
                    .value

                return PrvKeyInfo(keyInfo: keyInfo, passphrase: passphrase)
            }

        return .success(privateKeys)
    }

    func getSigningKey() throws -> PrvKeyInfo? {
        guard let email = currentUserEmail() else {
            return nil
        }

        let keysInfo = storage.keysInfo()
            .filter { $0.account == email }

        guard let foundKey = try findKeyByUserEmail(keysInfo: keysInfo, email: email) else {
            return nil
        }

        let storedPassPhrases = passPhraseService.getPassPhrases()
        let passphrase = storedPassPhrases
            .filter { $0.value.isNotEmpty }
            .first(where: { $0.primaryFingerprint == foundKey.primaryFingerprint })?
            .value

        return PrvKeyInfo(
            private: foundKey.`private` ?? "",
            longid: foundKey.primaryFingerprint,
            passphrase: passphrase,
            fingerprints: foundKey.fingerprints
        )
    }

    private func findKeyByUserEmail(keysInfo: [KeyInfo], email: String) throws -> KeyDetails? {
        let f: (KeyInfo) throws -> KeyDetails? = { keyInfo in
            let parsedKeys = try self.coreService.parseKeys(
                armoredOrBinary: keyInfo.`private`.data()
            )

            var keyDetails: [KeyDetails] = []
            parsedKeys.keyDetails.forEach { keyDetails.append($0) }

            return keyDetails.first {
                let emails = $0.pgpUserEmails
                return emails.first == email || emails.contains(where: { $0 == email })
            }
        }

        return try keysInfo.compactMap(f).first
    }
}
