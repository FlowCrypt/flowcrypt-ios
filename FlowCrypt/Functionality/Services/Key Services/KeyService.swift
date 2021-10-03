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
    func getPrvKeyInfo(with passPhrase: String?) -> Result<[PrvKeyInfo], KeyServiceError>
}

enum KeyServiceError: Error {
    case unexpected, parsingError, retrieve, missedPassPhrase
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

    /// Use to get list of PrvKeyInfo with pass phrase
    func getPrvKeyInfo(with passPhrase: String? = nil) -> Result<[PrvKeyInfo], KeyServiceError> {
        guard let email = currentUserEmail() else {
            return .failure(.retrieve)
        }

        let keysInfo = storage.keysInfo()
            .filter { $0.account == email }

        let storedPassPhrases = passPhraseService.getPassPhrases()

        if passPhrase == nil, storedPassPhrases.isEmpty {
            // in case there are no pass phrases in storage/memory
            // and user did not enter a pass phrase yet
            return .failure(.missedPassPhrase)
        }

        guard keysInfo.isNotEmpty else {
            return .success([])
        }

        // get all private keys with already saved pass phrases
        var privateKeys = keysInfo
            .compactMap { keyInfo -> PrvKeyInfo? in
                guard let passPhrase = storedPassPhrases.first(where: { $0.primaryFingerprint == keyInfo.primaryFingerprint }) else {
                    return nil
                }

                let passPhraseValue = passPhrase.value

                guard passPhraseValue.isNotEmpty else {
                    return nil
                }

                return PrvKeyInfo(
                    private: keyInfo.private,
                    longid: keyInfo.primaryLongid,
                    passphrase: passPhraseValue,
                    fingerprints: Array(keyInfo.allFingerprints)
                )
            }

        // append keys to ensure with a pass phrase
        let keysToEnsure: [PrvKeyInfo] = keysInfo.compactMap {
            guard let passPhraseValue = $0.passphrase ?? passPhrase else { return nil }

            return PrvKeyInfo(
                private: $0.private,
                longid: $0.primaryLongid,
                passphrase: passPhraseValue,
                fingerprints: Array($0.allFingerprints)
            )
        }

        privateKeys.append(contentsOf: keysToEnsure)

        return .success(privateKeys)
    }
}
