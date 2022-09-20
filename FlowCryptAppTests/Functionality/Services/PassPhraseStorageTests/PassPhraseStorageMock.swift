//
//  EncryptedPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt

class PassPhraseStorageMock: PassPhraseStorageType {

    var saveResult: ((PassPhrase) -> Void)?
    func save(passPhrase: PassPhrase) {
        saveResult?(passPhrase)
    }

    var updateResult: ((PassPhrase) -> Void)?
    func update(passPhrase: PassPhrase) {
        updateResult?(passPhrase)
    }

    var isRemovePassPhraseResult: ((PassPhrase) -> Void)?
    func remove(passPhrase: PassPhrase) {
        isRemovePassPhraseResult?(passPhrase)
    }

    var getPassPhrasesResult: () -> ([PassPhrase]) = {
        [
            PassPhrase(value: "a", email: "passphrase@account.test", fingerprintsOfAssociatedKey: ["11","12"]),
            PassPhrase(value: "2", email: "passphrase@account.test", fingerprintsOfAssociatedKey: ["21","22"])
        ]
    }
    func getPassPhrases(for email: String) -> [PassPhrase] {
        getPassPhrasesResult()
    }

    func removePassPhrases(for email: String) throws {
        getPassPhrasesResult = { [] }
    }
}
