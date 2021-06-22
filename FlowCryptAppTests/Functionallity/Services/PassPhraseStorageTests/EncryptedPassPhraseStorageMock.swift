//
//  EncryptedPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
@testable import FlowCrypt

class EncryptedPassPhraseStorageMock: EncryptedPassPhraseStorage {
    func addPassPhrase(object: PassPhraseObject) {
        
    }
    
    func updatePassPhrase(object: PassPhraseObject) {
        
    }
    
    var getPassPhrasesResult: () -> ([PassPhraseObject]) = {
        [PassPhraseObject(longid: "longid", value: "value")]
    }
    func getPassPhrases() -> [PassPhraseObject] {
        getPassPhrasesResult()
    }
    
    var isRemovePassPhraseResult: ((PassPhraseObject) -> ())?
    func removePassPhrase(object: PassPhraseObject) {
        isRemovePassPhraseResult?(object)
    }
    
    var keysInfoResult: () -> ([KeyInfo]) = { [] }
    func keysInfo() -> [KeyInfo] {
        keysInfoResult()
    }
}
