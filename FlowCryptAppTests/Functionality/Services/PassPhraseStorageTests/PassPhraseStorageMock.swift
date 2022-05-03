//
//  EncryptedPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

class PassPhraseStorageMock: PassPhraseStorageType & LogOutHandler {

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
            PassPhrase(value: "a", fingerprintsOfAssociatedKey: ["11","12"]),
            PassPhrase(value: "2", fingerprintsOfAssociatedKey: ["21","22"])
        ]
    }
    func getPassPhrases(for email: String) -> [PassPhrase] {
        getPassPhrasesResult()
    }

    func logOutUser(email: String) throws {
    }
}
