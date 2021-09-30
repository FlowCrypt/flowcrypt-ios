//
//  EncryptedPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
@testable import FlowCrypt

class PassPhraseStorageMock: PassPhraseStorageType {
    
    var saveResult: ((PassPhrase) -> ())?
    func save(passPhrase: PassPhrase) {
        saveResult?(passPhrase)
    }
    
    var updateResult: ((PassPhrase) -> ())?
    func update(passPhrase: PassPhrase) {
        updateResult?(passPhrase)
    }
    
    var isRemovePassPhraseResult: ((PassPhrase) -> ())?
    func remove(passPhrase: PassPhrase) {
        isRemovePassPhraseResult?(passPhrase)
    }
    
    var getPassPhrasesResult: () -> ([PassPhrase]) = {
        [
            PassPhrase(value: "a", fingerprints: ["11","12"]),
            PassPhrase(value: "2", fingerprints: ["21","22"])
        ]
    }
    func getPassPhrases() -> [PassPhrase] {
        getPassPhrasesResult()
    }
}
