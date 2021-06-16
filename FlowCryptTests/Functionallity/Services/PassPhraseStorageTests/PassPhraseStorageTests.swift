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
    
    func testSavePassPhraseInStorage() {
        let passPhraseToSave = PassPhrase(value: "pass", longid: "12345")
        
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1
        expectation.isInverted = true
        
        // encrypted storage contains pass phrase which should be saved locally
        storage.getPassPhrasesResult = {
            [
                PassPhraseObject(longid: "12345", value: "pass")
            ]
        }
        
        
        // encrypted storage should not contains pass phrase which user decide to save locally
        storage.isRemovePassPhraseResult = { passPhraseToRemove in
            if passPhraseToRemove.longid == "12345" {
                expectation.fulfill()
            }
        }
        
        sut.savePassPhrase(with: passPhraseToSave, inStorage: true)
        
        XCTAssertFalse(localStorage.isSaveCalled)
        
        wait(for: [expectation], timeout: 0.1, enforceOrder: false)
    }
    
    func testSavePassPhraseInStorageWithoutAnyPassPhrases() {
        let passPhraseToSave = PassPhrase(value: "pass", longid: "12345")
        
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        
        // encrypted storage is empty
        storage.getPassPhrasesResult = { [ ] }
        
        storage.isRemovePassPhraseResult = { _ in
            expectation.fulfill()
        }
        
        sut.savePassPhrase(with: passPhraseToSave, inStorage: true)
        
        XCTAssertFalse(localStorage.isSaveCalled)
        
        wait(for: [expectation], timeout: 0.1, enforceOrder: false)
    }
    
    func testSavePassPhraseInMemory() {
        let passPhraseToSave = PassPhrase(value: "pass", longid: "12345")
        sut.savePassPhrase(with: passPhraseToSave, inStorage: false)

        XCTAssertTrue(localStorage.isSaveCalled)
    }
}

extension KeyInfo {
    // extend with more parameters if needed
    static func mock(
        with publicValue: String,
        account: String = "",
        longid: String
    ) -> KeyInfo {
        let key = try! KeyInfo(
            KeyDetails(
                public: publicValue,
                private: "private",
                isFullyDecrypted: true,
                isFullyEncrypted: true,
                ids: [
                    KeyId(shortid: "shortId", longid: "longid", fingerprint: "fingerprint", keywords: "keywords")
                ],
                created: 1234,
                users: [],
                algo: nil
            ),
            source: .backup
        )
        key.account = account
        key.longid = longid
        return key
    }
}
