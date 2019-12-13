//
//  KeySettingsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeySettingsProviderType {
    func getPublickKeys() -> Result<[KeySettingsItem], KeySettingsError>
}

enum KeySettingsError: Swift.Error {
    case fetching, parsing
}

struct KeySettingsProvider: KeySettingsProviderType {
    static var shared: KeySettingsProvider = KeySettingsProvider(
        dataManager: DataManager.shared,
        core: Core.shared
    )

    private let dataManager: DataManagerType
    private let core: Core

    func getPublickKeys() -> Result<[KeySettingsItem], KeySettingsError> {
        guard let keys = dataManager.keys() else {
            return .failure(.fetching)
        }

        var isAnyErrorInKeyParsing = false

        let items = keys
            .compactMap { (privateKeys: PrvKeyInfo) -> [KeyDetails]? in
                do {
                    let parsedKey = try core.parseKeys(
                        armoredOrBinary: privateKeys.private.data()
                    )
                    return parsedKey.keyDetails
                } catch {
                    isAnyErrorInKeyParsing = true
                    return nil
                }
            }
            .flatMap { $0 }
            .compactMap(KeySettingsItem.init)

        // in case we have multiple keys and error was only in one key parsing
        if isAnyErrorInKeyParsing && items.isEmpty {
            return .failure(.parsing)
        } else { 
            return .success(items)
        }
    }
}
