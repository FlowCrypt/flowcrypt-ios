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
    case emptyKeys, unexpected, parsingError, retrieve
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
        guard let privateKeys = try? getPrivateKeys().get(), privateKeys.isNotEmpty else {
            return .failure(.emptyKeys)
        }

        let keyDetails = privateKeys
            .compactMap {
                try? coreService.parseKeys(armoredOrBinary: $0.private.data())
                    .keyDetails
            }
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

        guard keysInfo.isNotEmpty else {
            return .failure(.emptyKeys)
        }

        // get all private keys with already saved pass phrases
        var privateKeys = keysInfo
            .compactMap { keyInfo -> PrvKeyInfo? in
                guard let passPhrase = storedPassPhrases.first(where: { $0.longid == keyInfo.longid }) else {
                    return nil
                }

                let passPhraseValue = passPhrase.value

                guard passPhraseValue.isNotEmpty else {
                    return nil
                }

                return PrvKeyInfo(
                    private: keyInfo.private,
                    longid: keyInfo.longid,
                    passphrase: passPhraseValue
                )
            }

        // append keys to ensure with a pass phrase
        if let passPhrase = passPhrase {
            let keysToEnsure = keysInfo.map {
                PrvKeyInfo(
                    private: $0.private,
                    longid: $0.longid,
                    passphrase: passPhrase
                )
            }

            privateKeys.append(contentsOf: keysToEnsure)
        }

        guard privateKeys.isNotEmpty else {
            return .failure(.emptyKeys)
        }

        return .success(privateKeys)
    }
}
