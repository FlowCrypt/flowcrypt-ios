//
//  KeyService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

// Data Service
protocol KeyDataServiceType {
    var keys: [PrvKeyInfo]? { get }
    var publicKey: String? { get }
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func updateKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
}

protocol KeyServiceType {
    func retrieveKeyDetails() -> Result<[KeyDetails], KeyServiceError>
}

enum KeyServiceError: Error {
    case retrieve
    case parse
    case unexpected
}

struct KeyService: KeyServiceType {
    let coreService: Core = .shared
    let dataService: KeyDataServiceType = DataService.shared

    func retrieveKeyDetails() -> Result<[KeyDetails], KeyServiceError> {
        guard let keys = dataService.keys else {
            return .failure(.retrieve)
        }

        let keyDetails = keys
            .compactMap {
                try? coreService
                    .parseKeys(armoredOrBinary: $0.private.data())
                    .keyDetails
            }
            .flatMap { $0 }

        guard keyDetails.count == keys.count else {
            return .failure(.parse)
        }

        return .success(keyDetails)
    }
}
