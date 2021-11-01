//
//  KeyMethodsTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 20.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class KeyMethodsTest: XCTestCase {

    var sut: KeyMethods!
    var decrypter: MockKeyDecrypter!
    var passPhrase = "Some long frase"

    override func setUp() {
        decrypter = MockKeyDecrypter()
        sut = KeyMethods(decrypter: decrypter)
    }

    func testEmptyParsingKey() async throws {
        let emptyKeys: [KeyDetails] = []
        let result = try await sut.filterByPassPhraseMatch(keys: emptyKeys, passPhrase: passPhrase)

        XCTAssertTrue(result.isEmpty)
    }

    func testPassPublicKeyWhenExpectingPrivateForPassPhraseMatch() async throws {
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
                lastModified: nil,
                expiration: nil,
                users: [],
                algo: nil,
                revoked: false
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
                lastModified: nil,
                expiration: nil,
                users: [],
                algo: nil,
                revoked: false
            )
        ]
        do {
            try await sut.filterByPassPhraseMatch(keys: keys, passPhrase: passPhrase)
            XCTFail("expected to throw above")
        } catch {
            XCTAssertEqual(error as? KeyServiceError, KeyServiceError.expectedPrivateGotPublic)
        }
    }

    func testCantDecryptKey() async throws {
        decrypter.result = .failure(.some)
        let result = try await sut.filterByPassPhraseMatch(keys: validKeys, passPhrase: passPhrase)
        XCTAssertTrue(result.isEmpty)
    }

    func testSuccessDecryption() async throws {
        decrypter.result = .success(CoreRes.DecryptKey(decryptedKey: "some key"))
        let result = try await sut.filterByPassPhraseMatch(keys: validKeys, passPhrase: passPhrase)
        XCTAssertTrue(result.isNotEmpty)
    }
}

extension KeyMethodsTest {
    var validKeys: [KeyDetails] { [
        KeyDetails(
            public: "Public part",
            private: "private 1",
            isFullyDecrypted: false,
            isFullyEncrypted: false,
            ids: [
                KeyId(longid: "longid", fingerprint: "fingerprint")
            ],
            created: 1,
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
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
            lastModified: nil,
            expiration: nil,
            users: [],
            algo: nil,
            revoked: false
        )
    ] }
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
