//
//  EncryptedPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
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
            PassPhrase(value: "a", longid: "1"),
            PassPhrase(value: "2", longid: "2")
        ]
    }
    func getPassPhrases() -> [PassPhrase] {
        getPassPhrasesResult()
    }
}
