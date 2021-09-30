//
//  KeyMethodsTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 20.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class KeyMethodsTest: XCTestCase {

    var sut: KeyMethods!
    var decrypter: MockKeyDecrypter!
    var passPhrase = "Some long frase"
    
    override func setUp() {
        decrypter = MockKeyDecrypter()
        sut = KeyMethods(decrypter: decrypter)
    }
    
    func testEmptyParsingKey() {
        let emptyKeys: [KeyDetails] = []
        let result = sut.filterByPassPhraseMatch(keys: emptyKeys, passPhrase: passPhrase)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testNoPrivateKey() {
        // private part = nil
        let keys = [
            KeyDetails(
                public: "Public part",
                private: nil,
                isFullyDecrypted: false,
                isFullyEncrypted: false,
                ids: [
                    KeyId(longid: "longid", fingerprint: "fingerprint")
                ],
                created: 1,
                users: [],
                algo: nil
            ),
            KeyDetails(
                public: "Public part2",
                private: nil,
                isFullyDecrypted: false,
                isFullyEncrypted: false,
                ids: [
                    KeyId(longid: "longid 2", fingerprint: "fingerprint 2")
                ],
                created: 1,
                users: [],
                algo: nil
            )
        ]
        let result = sut.filterByPassPhraseMatch(keys: keys, passPhrase: passPhrase)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testCantDecryptKey() {
        decrypter.result = .failure(.some)
        let result = sut.filterByPassPhraseMatch(keys: validKeys, passPhrase: passPhrase)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testSuccessDecryption() {
        decrypter.result = .success(CoreRes.DecryptKey(decryptedKey: "some key"))
        let result = sut.filterByPassPhraseMatch(keys: validKeys, passPhrase: passPhrase)
        XCTAssertTrue(result.isNotEmpty)
    }
}

extension KeyMethodsTest {
    var validKeys: [KeyDetails] {[
        KeyDetails(
            public: "Public part",
            private: "private 1",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [
                KeyId(longid: "longid", fingerprint: "fingerprint")
            ],
            created: 1,
            users: [],
            algo: nil
        ),
        KeyDetails(
            public: "Public part2",
            private: "private 2",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [
                KeyId(longid: "longid2", fingerprint: "fingerprint2")
            ],
            created: 1,
            users: [],
            algo: nil
        )
    ]}
}

class MockKeyDecrypter: KeyDecrypter {
    var result: Result<CoreRes.DecryptKey, MockError> = .success(CoreRes.DecryptKey(decryptedKey: "decrypted"))
    
    func decryptKey(armoredPrv: String, passphrase: String) throws -> CoreRes.DecryptKey {
        switch result {
        case .success(let key):
            return key
        case .failure(let error):
            throw error
        }
    }
}
