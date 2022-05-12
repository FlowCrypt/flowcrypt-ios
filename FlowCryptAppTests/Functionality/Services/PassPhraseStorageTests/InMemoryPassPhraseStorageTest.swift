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
    var encryptedStorageMock: EncryptedStorageMock!
    var timeoutInSeconds: Int!
    let testPassPhraseAccount = "passphrase@account.test"

    override func setUp() {
        passPhraseProvider = InMemoryPassPhraseProviderMock()
        timeoutInSeconds = 2
        encryptedStorageMock = EncryptedStorageMock()
        sut = .init(
            passPhraseProvider: passPhraseProvider,
            encryptedStorage: encryptedStorageMock,
            timeoutInSeconds: timeoutInSeconds
        )
    }

    func testSavePassPhraseUpdatesDate() {
        let pass = PassPhrase(value: "A", fingerprintsOfAssociatedKey: ["11","12"])
        sut.save(passPhrase: pass)
        for passPhrase in passPhraseProvider.passPhrases {
            XCTAssertNotNil(passPhrase.date)
        }
    }

    func testUpdatePassPhraseUpdatesDate() {
        let pass = PassPhrase(value: "A", fingerprintsOfAssociatedKey: ["11","12"])
        sut.update(passPhrase: pass)
        for passPhrase in passPhraseProvider.passPhrases {
            XCTAssertNotNil(passPhrase.date)
        }
    }

    func testRemovePassPhrase() {
        let pass = PassPhrase(value: "A", fingerprintsOfAssociatedKey: ["11","12"])
        sut.save(passPhrase: pass)
        sut.remove(passPhrase: pass)
        XCTAssertTrue(passPhraseProvider.passPhrases.isEmpty)
    }

    func testGetPassPhrases() throws {
        let fingerPrints = ["11","12"]
        try encryptedStorageMock.mockGetKeyPairs(with: fingerPrints)

        var passPhrases = try sut.getPassPhrases(for: testPassPhraseAccount)
        XCTAssertTrue(passPhrases.isEmpty)

        let pass = PassPhrase(value: "A", fingerprintsOfAssociatedKey: fingerPrints)
        sut.save(passPhrase: pass)

        passPhrases = try sut.getPassPhrases(for: testPassPhraseAccount)
        XCTAssertTrue(passPhrases.count == 1)
        XCTAssertTrue(passPhrases.contains(
            where: { $0.primaryFingerprintOfAssociatedKey == "11" })
        )
        XCTAssertTrue(passPhrases.filter { $0.date == nil }.isEmpty)
    }

    func testExpiredPassPhrases() {
        XCTAssertTrue(try sut.getPassPhrases(for: testPassPhraseAccount).isEmpty)

        let pass = PassPhrase(value: "A", fingerprintsOfAssociatedKey: ["11","12"])
        sut.save(passPhrase: pass)
        sleep(3)
        XCTAssertTrue(try sut.getPassPhrases(for: testPassPhraseAccount).isEmpty)
    }
}

class InMemoryPassPhraseProviderMock: InMemoryPassPhraseProviderType {
    var passPhrases: Set<PassPhrase> = []

    func save(passPhrase: PassPhrase) {
        passPhrases.insert(passPhrase)
    }

    func remove(passPhrases passPhrasesToDelete: Set<PassPhrase>) {
        for passPhraseToDelete in passPhrasesToDelete {
            passPhrases.remove(passPhraseToDelete)
        }
    }
}
