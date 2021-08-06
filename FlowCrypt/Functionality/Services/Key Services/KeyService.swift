//
//  KeyService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeyServiceType {
    func retrieveKeyDetails() -> Result<[KeyDetails], KeyServiceError>
    func getPrivateKeys(with passPhrase: String?) -> Result<[PrvKeyInfo], KeyServiceError>
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

    func retrieveKeyDetails() -> Result<[KeyDetails], KeyServiceError> {
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

    func getPrivateKeys(with passPhrase: String? = nil) -> Result<[PrvKeyInfo], KeyServiceError> {
        guard let email = currentUserEmail() else {
            return .failure(.retrieve)
        }

        let keysInfo = storage.keysInfo()
            .filter { $0.account == email }

        let storedPassPhrases = passPhraseService.getPassPhrases()

        if passPhrase == nil, storedPassPhrases.isEmpty {
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
        if let passPhrase = passPhrase {
            let keysToEnsure = keysInfo.map {
                PrvKeyInfo(
                    private: $0.private,
                    longid: $0.primaryLongid,
                    passphrase: passPhrase,
                    fingerprints: Array($0.allFingerprints)
                )
            }

            privateKeys.append(contentsOf: keysToEnsure)
        }

        return .success(privateKeys)
    }
}
