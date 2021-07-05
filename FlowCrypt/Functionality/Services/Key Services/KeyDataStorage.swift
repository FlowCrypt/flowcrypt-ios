//
//  KeyDataStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

final class KeyDataStorage {
    private lazy var logger = Logger.nested(Self.self)

    private let encryptedStorage: EncryptedStorageType

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage()
    ) {
        self.encryptedStorage = encryptedStorage
    }
}

extension KeyDataStorage: KeyStorageType {
    func updateKeys(keyDetails: [KeyDetails], source: KeySource) {
        encryptedStorage.updateKeys(keyDetails: keyDetails, source: source)
    }

    func publicKey() -> String? {
        encryptedStorage.publicKey()
    }

    func keysInfo() -> [KeyInfo] {
        encryptedStorage.keysInfo()
    }

    func addKeys(keyDetails: [KeyDetails], source: KeySource) {
        debugPrint("Tom: keyDetails \(keyDetails)")

        keyDetails.forEach {
            debugPrint("Tom: keyDetails - Add keys for \($0.users)")
            logger.logInfo("Add keys for \($0.users)")
        }
        encryptedStorage.addKeys(keyDetails: keyDetails, source: source)
    }
}
