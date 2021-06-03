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
    case emptyKeys, unexpected, parsingError, retrieve, test // TODO: - ANTON
}

struct KeyService: KeyServiceType {
    let coreService: Core = .shared
    let dataService: KeyDataStorageType = KeyDataStorage()

    func retrieveKeyDetails() -> Result<[KeyDetails], KeyServiceError> {
        let keysInfo = dataService.keysInfo

        // TODO: - ANTON - Match all keysInfo
        // TODO: - ANTON - get all available pass phrases
        // TODO: - ANTON - match them by longId to create PrvKeyInfo
        // TODO: - ANTON - Handle error by showing alert for user

        let privateKeys: [PrvKeyInfo] = []

//        let keys = dataService.privateKeys
        guard privateKeys.isNotEmpty else {
            return .failure(.emptyKeys)
        }

        let keyDetails = privateKeys
            .compactMap {
                try? coreService
                    .parseKeys(armoredOrBinary: $0.private.data())
                    .keyDetails
            }
            .flatMap { $0 }

        guard keyDetails.count == privateKeys.count else {
            return .failure(.parsingError)
        }

        return .success(keyDetails)
    }

    func getPrivateKeys() -> Result<[PrvKeyInfo], KeyServiceError> {
        .failure(.test)
    }
}
