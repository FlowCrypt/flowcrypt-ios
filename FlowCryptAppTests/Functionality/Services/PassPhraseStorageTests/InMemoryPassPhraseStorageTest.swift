//
//  InMemoryPassPhraseStorageTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 23.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class InMemoryPassPhraseStorageTest: XCTestCase {
    var sut: InMemoryPassPhraseStorage!
    var passPhraseProvider: InMemoryPassPhraseProviderType!
    var timeoutInSeconds: Int!
    let testPassPhraseAccount = "passphrase@account.test"
    var testPassPhrase: PassPhrase!

    override func setUp() {
        passPhraseProvider = InMemoryPassPhraseProviderMock()
        testPassPhrase = PassPhrase(
            value: "A",
            email: testPassPhraseAccount,
            fingerprintsOfAssociatedKey: ["11","12"]
        )
        sut = .init(
            passPhraseProvider: passPhraseProvider
        )
    }

    func testSavePassPhraseUpdatesDate() {
        sut.save(passPhrase: testPassPhrase)
        for passPhrase in passPhraseProvider.passPhrases {
            XCTAssertNotNil(passPhrase.date)
        }
    }

    func testUpdatePassPhraseUpdatesDate() {
        sut.update(passPhrase: testPassPhrase)
        for passPhrase in passPhraseProvider.passPhrases {
            XCTAssertNotNil(passPhrase.date)
        }
    }

    func testRemovePassPhrase() {
        sut.save(passPhrase: testPassPhrase)
        sut.remove(passPhrase: testPassPhrase)
        XCTAssertTrue(passPhraseProvider.passPhrases.isEmpty)
    }

    func testGetPassPhrases() throws {
        var passPhrases = try sut.getPassPhrases(for: testPassPhraseAccount, expirationInSeconds: 10)
        XCTAssertTrue(passPhrases.isEmpty)

        sut.save(passPhrase: testPassPhrase)

        passPhrases = try sut.getPassPhrases(for: testPassPhraseAccount, expirationInSeconds: 10)
        XCTAssertTrue(passPhrases.count == 1)
        XCTAssertTrue(passPhrases.contains(
            where: { $0.primaryFingerprintOfAssociatedKey == "11" })
        )
        XCTAssertTrue(passPhrases.filter { $0.date == nil }.isEmpty)
    }

    func testExpiredPassPhrases() async throws {
        let passphrase = try sut.getPassPhrases(for: testPassPhraseAccount, expirationInSeconds: 10)
        XCTAssertTrue(passphrase.isEmpty)

        sut.save(passPhrase: testPassPhrase)
        sleep(3)
        let newPassphrase = try sut.getPassPhrases(for: testPassPhraseAccount, expirationInSeconds: 2)
        XCTAssertTrue(newPassphrase.isEmpty)
    }
}

class InMemoryPassPhraseProviderMock: InMemoryPassPhraseProviderType {
    var passPhrases: Set<PassPhrase> = []

    func save(passPhrase: PassPhrase) {
        passPhrases.update(with: passPhrase)
    }

    func remove(passPhrases passPhrasesToDelete: Set<PassPhrase>) {
        for passPhraseToDelete in passPhrasesToDelete {
            passPhrases.remove(passPhraseToDelete)
        }
    }
}
