//
//  LocalPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

class LocalPassPhraseStorageMock: LocalPassPhraseStorageType {
    var passPhrases: Set<LocalPassPhrase> = []
    
    var isSaveCalled = false
    func save(passPhrase: LocalPassPhrase) {
        isSaveCalled = true
        passPhrases.insert(passPhrase)
        
        print("^^ \(passPhrases)")
    }
    
    func removePassPhrases(with objects: [LocalPassPhrase]) {
        objects.forEach {
            passPhrases.remove($0)
        }
    }
}
