//
//  PassPhraseStorageTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class PassPhraseStorageTests: XCTestCase {
    
    var sut: PassPhraseService!
    var encryptedStorage: PassPhraseStorageMock!
    var inMemoryStorage: PassPhraseStorageMock!
    var emailProvider: EmailProviderMock!
    
    override func setUp() {
        emailProvider = EmailProviderMock()
        encryptedStorage = PassPhraseStorageMock()
        inMemoryStorage = PassPhraseStorageMock()
        
        sut = PassPhraseService(
            encryptedStorage: encryptedStorage,
            localStorage: inMemoryStorage,
            emailProvider: emailProvider
        )
    }
    
    func testGetPassPhrasesWhenEmpty() {
        // no pass phrases in storage
        encryptedStorage.getPassPhrasesResult = { [] }
        // no pass phrases in localStorage
        inMemoryStorage.getPassPhrasesResult = { [] }
        
        let result = sut.getPassPhrases()
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testGetValidPassPhraseFromStorage() {
        let passPhrase1 = PassPhrase(
            value: "some",
            fingerprints: ["11","12"]
        )
        let passPhrase2 = PassPhrase(
            value: "some",
            fingerprints: ["21","22"]
        )
        
        encryptedStorage.getPassPhrasesResult = { [passPhrase1] }
        // no pass phrases in localStorage
        inMemoryStorage.getPassPhrasesResult = { [] }
        
        var result = sut.getPassPhrases()
        
        XCTAssertTrue(result.count == 1)
        
        encryptedStorage.getPassPhrasesResult = {
            [passPhrase1, passPhrase2]
        }
        
        result = sut.getPassPhrases()
        
        XCTAssertTrue(result.count == 2)
    }
    
    func testGetValidPassPhraseInLocalStorage() {
        encryptedStorage.getPassPhrasesResult = { [] }
        
        let savedDate = Date()
        let localPassPhrase = PassPhrase(
            value: "value",
            fingerprints: ["f1"],
            date: savedDate
        )
        inMemoryStorage.getPassPhrasesResult = { [localPassPhrase] }
        
        // current timeout = 2
        sleep(1)
        
        let result = sut.getPassPhrases()
        XCTAssertTrue(result.isNotEmpty)
    }
    
    func testBothStorageContainsValidPassPhrase() {
        let passPhrase1 = PassPhrase(
            value: "some",
            fingerprints: ["A123"]
        )
        let passPhrase2 = PassPhrase(
            value: "some",
            fingerprints: ["A123"]
        )
        encryptedStorage.getPassPhrasesResult = {
            [passPhrase1, passPhrase2]
        }
        
        let savedDate = Date()
        let localPassPhrase = PassPhrase(
            value: "value",
            fingerprints: ["123444"],
            date: savedDate
        )
        
        inMemoryStorage.getPassPhrasesResult = { [localPassPhrase] }
        
        let result = sut.getPassPhrases()
        XCTAssertTrue(result.count == 3)
    }
    
    func testSavePassPhraseInStorage() {
        let passPhraseToSave = PassPhrase(value: "pass", fingerprints: ["fingerprint 1", "123333"])
        
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1
        expectation.isInverted = true
        
        // encrypted storage contains pass phrase which should be saved locally
        encryptedStorage.getPassPhrasesResult = {
            [
                PassPhrase(value: "pass", fingerprints: ["fingerprint 1", "adfnhjfg"])
            ]
        }
        
        
        // encrypted storage should not contains pass phrase which user decide to save locally
        encryptedStorage.isRemovePassPhraseResult = { passPhraseToRemove in
            if passPhraseToRemove.primaryFingerprint == "fingerprint 1" {
                expectation.fulfill()
            }
        }
        
        sut.savePassPhrase(with: passPhraseToSave, inStorage: true)
        
        XCTAssertFalse(inMemoryStorage.saveResult != nil )
        
        wait(for: [expectation], timeout: 0.1, enforceOrder: false)
    }
    
    func testSavePassPhraseInStorageWithoutAnyPassPhrases() {
        let passPhraseToSave = PassPhrase(value: "pass", fingerprints: ["fingerprint 1", "123333"])
        
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        
        // encrypted storage is empty
        encryptedStorage.getPassPhrasesResult = { [ ] }
        
        encryptedStorage.isRemovePassPhraseResult = { _ in
            expectation.fulfill()
        }
        
        sut.savePassPhrase(with: passPhraseToSave, inStorage: true)
        
        XCTAssertFalse(inMemoryStorage.saveResult != nil )
        
        wait(for: [expectation], timeout: 0.1, enforceOrder: false)
    }

}

extension KeyInfo {
    // extend with more parameters if needed
    static func mock(
        with publicValue: String,
        account: String = "",
        longid: String
    ) -> KeyInfo {
        try! KeyInfo(
            KeyDetails(
                public: publicValue,
                private: "private",
                isFullyDecrypted: true,
                isFullyEncrypted: true,
                ids: [
                    KeyId(longid: "longid", fingerprint: "fingerprint")
                ],
                created: 1234,
                users: [],
                algo: nil
            ),
            source: .backup,
            user: UserObject(
                name: "name",
                email: "email@gmail.com",
                imap: nil,
                smtp: nil
            )
        )
    }
}
