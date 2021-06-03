//
//  PassPhraseStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol PassPhraseStorageType {
    func getPassPhrases() -> [PassPhrase]
}

final class PassPhraseStorage: PassPhraseStorageType {
    let storage: EncryptedStorage
    let localStorage: UserDefaults

    init(
        storage: EncryptedStorage = EncryptedStorage(),
        localStorage: UserDefaults = .standard
    ) {
        self.storage = storage
        self.localStorage = localStorage
    }

    func savePassPhrase(with passPhrase: PassPhrase) {
//        if context.isLocally {
//            storage.addKeys(keyDetails: context.keys, passPhrase: context.passPhrase, source: context.source)
//        } else {
//            // TODO: - ANTON
//        }
    }

    func getPassPhrases() -> [PassPhrase] {
        []
    }
}

struct PassPhrase {
    let value: String
    let longId: String
}
