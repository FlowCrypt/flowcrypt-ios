//
//  PassPhraseStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class PassPhraseStorageService {
    struct Context {
        let passPhrase: String
        let keys: [KeyDetails]
        let source: KeySource
        let isLocally: Bool
    }

    let storage: KeyStorageType

    init(storage: KeyStorageType = EncryptedStorage()) {
        self.storage = storage
    }

    func savePassPhrase(with context: Context) {
        if context.isLocally {
            storage.addKeys(keyDetails: context.keys, passPhrase: context.passPhrase, source: context.source)
        } else {
            // TODO: - ANTON
        }
    }
}

import RealmSwift
class KeyStorageMock: KeyStorageType {
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
    }

    var publicKeyResult: () -> (String?) = { nil }
    func publicKey() -> String? {
        publicKeyResult()
    }

    var keysResult: () -> ([KeyInfo]) = { [] }
    func keys() -> [KeyInfo] {
        keysResult()
    }
}
