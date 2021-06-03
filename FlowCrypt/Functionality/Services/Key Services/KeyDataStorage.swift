//
//  KeyDataStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol KeyDataStorageType {
    var keysInfo: [KeyInfo] { get }
    var publicKey: String? { get }
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func updateKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
}

final class KeyDataStorage {
    private let encryptedStorage: EncryptedStorageType
    private let passPhraseStorage: PassPhraseStorageType

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage(),
        passPhraseStorage: PassPhraseStorageType = PassPhraseStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.passPhraseStorage = passPhraseStorage
    }
}

extension KeyDataStorage: KeyDataStorageType {
    var keysInfo: [KeyInfo] {
        encryptedStorage.keysInfo()
    }

    var publicKey: String? {
        encryptedStorage.publicKey()
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.addKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.updateKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
    }
}
