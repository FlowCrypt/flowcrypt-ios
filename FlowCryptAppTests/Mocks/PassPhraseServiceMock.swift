//
//  PassPhraseServiceMock.swift
//  FlowCryptAppTests
//
//  Created by  Ivan Ushakov on 15.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt

final class PassPhraseServiceMock: PassPhraseServiceType {

    func savePassPhrasesInMemory(_ passPhrase: String, for privateKeys: [PrvKeyInfo]) {
    }

    var passPhrases: [PassPhrase] = []

    func getPassPhrases(for email: String) -> [PassPhrase] {
        passPhrases
    }

    func savePassPhrase(with passPhrase: PassPhrase, storageMethod: StorageMethod) {
    }

    func updatePassPhrase(with passPhrase: PassPhrase, storageMethod: StorageMethod) {
    }
}
