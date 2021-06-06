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
    func getPrivateKeys() -> Result<[PrvKeyInfo], KeyServiceError>
}

enum KeyServiceError: Error {
    case emptyKeys, unexpected, parsingError, retrieve
}

final class KeyService: KeyServiceType {
    let coreService: Core = .shared
    let storage: KeyStorageType
    let passPhraseStorage: PassPhraseStorageType
    let currentUserEmail: () -> (String?)

    init(
        storage: KeyStorageType = KeyDataStorage(),
        passPhraseStorage: PassPhraseStorageType = PassPhraseStorage(),
        currentUserEmail: @autoclosure @escaping () -> (String?) = DataService.shared.email
    ) {
        self.storage = storage
        self.passPhraseStorage = passPhraseStorage
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

    func getPrivateKeys() -> Result<[PrvKeyInfo], KeyServiceError> {
        guard let email = currentUserEmail() else {
            return .failure(.retrieve)
        }

        let keysInfo = storage.keysInfo()
            .filter { $0.account.contains(email) }

        let passPhrases = passPhraseStorage.getPassPhrases()

        guard keysInfo.isNotEmpty, passPhrases.isNotEmpty else {
            return .failure(.emptyKeys)
        }

        let privateKeys = keysInfo.compactMap { (keyInfo) -> PrvKeyInfo? in
            guard let passPhrase = passPhrases.first(where: { $0.longid == keyInfo.longid }) else {
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

        guard privateKeys.isNotEmpty else {
            return .failure(.emptyKeys)
        }

        return .success(privateKeys)
    }
}
