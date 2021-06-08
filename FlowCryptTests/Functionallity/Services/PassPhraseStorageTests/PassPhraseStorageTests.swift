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
            timeoutContext: (Calendar.Component.second, 2),
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
    
    func testGetValidPassPhraseFromStorage() {
        let passPhrase1 = PassPhraseObject(
            longid: "A123",
            value: "some"
        )
        let passPhrase2 = PassPhraseObject(
            longid: "A123",
            value: "some"
        )
        
        storage.getPassPhrasesResult = { [passPhrase1] }
        // no pass phrases in localStorage
        localStorage.passPhrases = []
        
        var result = sut.getPassPhrases()
        
        XCTAssertTrue(result.count == 1)
        
        storage.getPassPhrasesResult = {
            [passPhrase1, passPhrase2]
        }
        
        result = sut.getPassPhrases()
        
        XCTAssertTrue(result.count == 2)
    }

    func testGetValidPassPhraseInLocalStorage() {
        storage.getPassPhrasesResult = { [] }
        
        let savedDate = Date()
        let localPassPhrase = LocalPassPhrase(
            passPhrase: PassPhrase(
                value: "value",
                longid: "longid"),
            date: savedDate
        )
        localStorage.passPhrases = [localPassPhrase]
        
        // current timeout = 2
        sleep(1)
        
        let result = sut.getPassPhrases()
        XCTAssertTrue(result.isNotEmpty)
    }
    
    func testGetExpiredPassPhraseInLocalStorage() {
        storage.getPassPhrasesResult = { [] }
        
        let savedDate = Date()
        let localPassPhrase = LocalPassPhrase(
            passPhrase: PassPhrase(
                value: "value",
                longid: "longid"),
            date: savedDate
        )
        localStorage.passPhrases = [localPassPhrase]
        
        // current timeout = 2
        sleep(3)
        
        let result = sut.getPassPhrases()
        XCTAssertTrue(result.isEmpty)
    }
    
    func testBothStorageContainsValidPassPhrase() {
        let passPhrase1 = PassPhraseObject(
            longid: "A123",
            value: "some"
        )
        let passPhrase2 = PassPhraseObject(
            longid: "A123",
            value: "some"
        )
        
        storage.getPassPhrasesResult = {
            [passPhrase1, passPhrase2]
        }
        
        let savedDate = Date()
        let localPassPhrase = LocalPassPhrase(
            passPhrase: PassPhrase(
                value: "value",
                longid: "longid"),
            date: savedDate
        )
        
        localStorage.passPhrases = [localPassPhrase]
        
        let result = sut.getPassPhrases()
        XCTAssertTrue(result.count == 3)
    }
}
