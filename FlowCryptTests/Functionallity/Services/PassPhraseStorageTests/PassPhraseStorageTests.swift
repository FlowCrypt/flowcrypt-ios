//
//  PassPhraseStorageTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest

class PassPhraseStorageTests: XCTestCase {

    var sut: PassPhraseStorage!
    var storage: EncryptedPassPhraseStorageMock!
    var emailProvider: EmailProviderMock!
    var localStorage: LocalPassPhraseStorageMock!
    
    override func setUp() {
        storage = EncryptedPassPhraseStorageMock()
        emailProvider = EmailProviderMock()
        localStorage = LocalPassPhraseStorageMock()
        
        sut = PassPhraseStorage(
            storage: storage,
            localStorage: localStorage,
            timeoutContext: (Calendar.Component.second, 4),
            emailProvider: emailProvider,
            isHours: false
        )
    }
    
    func testGetPassPhrasesWhenEmpty() {
        // no pass phrases in storage
        storage.getPassPhrasesResult = { [] }
        // no pass phrases in localStorage
        localStorage.passPhrases = []
        
        let result = sut.getPassPhrases()
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testValidPassPhraseInStorage() {
        let passPhrase = PassPhraseObject(
            longid: "A123",
            value: "some"
        )
        
        // no pass phrases in storage
        storage.getPassPhrasesResult = { [passPhrase] }
        // no pass phrases in localStorage
        localStorage.passPhrases = []
        
        let result = sut.getPassPhrases()
        
        XCTAssertTrue(result.count == 1)
    }

}
