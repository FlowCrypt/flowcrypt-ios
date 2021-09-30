//
//  PassPhraseStorageTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class PassPhraseStorageTests: XCTestCase {
    
    var sut: PassPhraseService!
    var inMemoryStorage: PassPhraseStorageMock!
    var emailProvider: EmailProviderMock!
    
    override func setUp() {
        emailProvider = EmailProviderMock()
        inMemoryStorage = PassPhraseStorageMock()
        
        sut = PassPhraseService(
            localStorage: inMemoryStorage,
            emailProvider: emailProvider
        )
    }
    
    func testGetPassPhrasesWhenEmpty() {
        // no pass phrases in localStorage
        inMemoryStorage.getPassPhrasesResult = { [] }
        
        let result = sut.getPassPhrases()
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testGetValidPassPhraseFromLocalStorage() {
        let passPhrase1 = PassPhrase(
            value: "some",
            fingerprints: ["11","12"]
        )
        let passPhrase2 = PassPhrase(
            value: "some",
            fingerprints: ["21","22"]
        )

        // no pass phrases in localStorage
        inMemoryStorage.getPassPhrasesResult = { [passPhrase1] }
        
        var result = sut.getPassPhrases()
        
        XCTAssertTrue(result.count == 1)
        
        inMemoryStorage.getPassPhrasesResult = {
            [passPhrase1, passPhrase2]
        }
        
        result = sut.getPassPhrases()
        
        XCTAssertTrue(result.count == 2)
    }
    
    func testGetValidPassPhraseInLocalStorage() {
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
    
    func testLocalStorageContainsValidPassPhrase() {
        let savedDate = Date()
        let localPassPhrase = PassPhrase(
            value: "value",
            fingerprints: ["123444"],
            date: savedDate
        )
        
        inMemoryStorage.getPassPhrasesResult = { [localPassPhrase] }
        
        let result = sut.getPassPhrases()
        XCTAssertTrue(result.count == 1)
    }
    
    func testSavePassPhraseInStorage() {
        let passPhraseToSave = PassPhrase(value: "pass", fingerprints: ["fingerprint 1", "123333"])
        
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1
        expectation.isInverted = true
        
        sut.savePassPhrase(with: passPhraseToSave, inStorage: true)
        
        XCTAssertFalse(inMemoryStorage.saveResult != nil )
        
        wait(for: [expectation], timeout: 0.1, enforceOrder: false)
    }
    
    func testSavePassPhraseInStorageWithoutAnyPassPhrases() {
        let passPhraseToSave = PassPhrase(value: "pass", fingerprints: ["fingerprint 1", "123333"])
        
        let expectation = XCTestExpectation()
        expectation.isInverted = true

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
            passphrase: nil,
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
