//
//  KeyDataStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

final class KeyDataStorage {
    private let encryptedStorage: EncryptedStorageType
    private let passPhraseStorage: PassPhraseStorageType

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage(),
        passPhraseStorage: PassPhraseStorageType = PassPhraseStorage(
            storage: EncryptedStorage(),
            emailProvider: DataService.shared
        )
    ) {
        self.encryptedStorage = encryptedStorage
        self.passPhraseStorage = passPhraseStorage
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
        encryptedStorage.addKeys(keyDetails: keyDetails, source: source)
    }
}
