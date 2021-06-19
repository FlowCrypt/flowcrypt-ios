//
//  LocalPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

class LocalPassPhraseStorageMock: InMemoryPassPhraseStorageType {
    var passPhrases: Set<InMemoryPassPhrase> = []
    
    var isSaveCalled = false
    func save(passPhrase: InMemoryPassPhrase) {
        isSaveCalled = true
        passPhrases.insert(passPhrase)
        
        print("^^ \(passPhrases)")
    }
    
    func removePassPhrases(with objects: [InMemoryPassPhrase]) {
        objects.forEach {
            passPhrases.remove($0)
        }
    }
}
