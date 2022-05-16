//
//  PassPhraseStorageTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class PassPhraseStorageTests: XCTestCase {

    var sut: CombinedPassPhraseStorage!
    var encryptedStorage: PassPhraseStorageMock!
    var inMemoryStorage: PassPhraseStorageMock!
    let testPassPhraseAccount = "passphrase@account.test"

    override func setUp() {
        encryptedStorage = PassPhraseStorageMock()
        inMemoryStorage = PassPhraseStorageMock()

        sut = CombinedPassPhraseStorage(
            encryptedStorage: encryptedStorage,
            inMemoryStorage: inMemoryStorage
        )
    }

    func testGetPassPhrasesWhenEmpty() throws {
        // no pass phrases in storage
        encryptedStorage.getPassPhrasesResult = { [] }
        // no pass phrases in localStorage
        inMemoryStorage.getPassPhrasesResult = { [] }

        let result = try sut.getPassPhrases(for: testPassPhraseAccount)

        XCTAssertTrue(result.isEmpty)
    }

    func testGetValidPassPhraseFromStorage() throws {
        let passPhrase1 = PassPhrase(
            value: "some",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["11","12"]
        )
        let passPhrase2 = PassPhrase(
            value: "some",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["21","22"]
        )

        encryptedStorage.getPassPhrasesResult = { [passPhrase1] }
        // no pass phrases in localStorage
        inMemoryStorage.getPassPhrasesResult = { [] }

        var result = try sut.getPassPhrases(for: testPassPhraseAccount)

        XCTAssertTrue(result.count == 1)

        encryptedStorage.getPassPhrasesResult = {
            [passPhrase1, passPhrase2]
        }

        result = try sut.getPassPhrases(for: testPassPhraseAccount)

        XCTAssertTrue(result.count == 2)
    }

    func testGetValidPassPhraseInLocalStorage() throws {
        encryptedStorage.getPassPhrasesResult = { [] }

        let savedDate = Date()
        let localPassPhrase = PassPhrase(
            value: "value",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["f1"],
            date: savedDate
        )
        inMemoryStorage.getPassPhrasesResult = { [localPassPhrase] }

        // current timeout = 2
        sleep(1)

        let result = try sut.getPassPhrases(for: testPassPhraseAccount)
        XCTAssertTrue(result.isNotEmpty)
    }

    func testBothStorageContainsValidPassPhrase() throws {
        let passPhrase1 = PassPhrase(
            value: "some",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["A123"]
        )
        let passPhrase2 = PassPhrase(
            value: "some",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["A123"]
        )
        encryptedStorage.getPassPhrasesResult = {
            [passPhrase1, passPhrase2]
        }

        let savedDate = Date()
        let localPassPhrase = PassPhrase(
            value: "value",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["123444"],
            date: savedDate
        )

        inMemoryStorage.getPassPhrasesResult = { [localPassPhrase] }

        let result = try sut.getPassPhrases(for: testPassPhraseAccount)
        XCTAssertTrue(result.count == 3)
    }

    func testSavePassPhraseInPersistenStorage() throws {
        let passPhraseToSave = PassPhrase(
            value: "pass",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["fingerprint 1", "123333"]
        )

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1
        expectation.isInverted = true

        // encrypted storage contains pass phrase which should be saved locally
        encryptedStorage.getPassPhrasesResult = {
            [
                PassPhrase(
                    value: "pass",
                    email: self.testPassPhraseAccount,
                    fingerprintsOfAssociatedKey: ["fingerprint 1", "adfnhjfg"]
                )
            ]
        }

        // encrypted storage should not contains pass phrase which user decide to save locally
        encryptedStorage.isRemovePassPhraseResult = { passPhraseToRemove in
            if passPhraseToRemove.primaryFingerprintOfAssociatedKey == "fingerprint 1" {
                expectation.fulfill()
            }
        }

        try sut.savePassPhrase(with: passPhraseToSave, storageMethod: .persistent)

        XCTAssertFalse(inMemoryStorage.saveResult != nil )

        wait(for: [expectation], timeout: 0.1, enforceOrder: false)
    }

    func testSavePassPhraseInPersistentStorageWithoutAnyPassPhrases() throws {
        let passPhraseToSave = PassPhrase(
            value: "pass",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["fingerprint 1", "123333"]
        )

        let expectation = XCTestExpectation()
        expectation.isInverted = true

        // encrypted storage is empty
        encryptedStorage.getPassPhrasesResult = { [ ] }

        encryptedStorage.isRemovePassPhraseResult = { _ in
            expectation.fulfill()
        }

        try sut.savePassPhrase(with: passPhraseToSave, storageMethod: .persistent)

        XCTAssertFalse(inMemoryStorage.saveResult != nil )

        wait(for: [expectation], timeout: 0.1, enforceOrder: false)
    }
}

extension KeypairRealmObject {
    // extend with more parameters if needed
    static func mock(
        with publicValue: String,
        account: String = "",
        longid: String
    ) -> KeypairRealmObject {
        try! KeypairRealmObject(
            KeyDetails(
                public: publicValue,
                private: "private",
                isFullyDecrypted: true,
                isFullyEncrypted: true,
                ids: [
                    KeyId(longid: "longid", fingerprint: "fingerprint")
                ],
                created: 1234,
                lastModified: nil,
                expiration: nil,
                users: [],
                algo: nil,
                revoked: false
            ),
            passphrase: nil,
            source: .backup,
            user: UserRealmObject(
                name: "name",
                email: "email@gmail.com",
                imap: nil,
                smtp: nil
            )
        )
    }
}
