//
//  LocalPassPhraseStorageMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

class LocalPassPhraseStorageMock: LocalPassPhraseStorageType {
    var getAllLocallySavedPassPhrasesResult: () -> ([LocalPassPhrase]) = { [] }
    func getAllLocallySavedPassPhrases() -> [LocalPassPhrase] {
        getAllLocallySavedPassPhrasesResult()
    }
    
    var encodeAndSaveResult: ([LocalPassPhrase]) -> () = { _ in
        
    }
    func encodeAndSave(passPhrases: [LocalPassPhrase]) {
        encodeAndSaveResult(passPhrases)
    }
}
