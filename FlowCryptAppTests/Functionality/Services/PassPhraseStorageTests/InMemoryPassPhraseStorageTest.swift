//
//  InMemoryPassPhraseStorageTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 23.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class InMemoryPassPhraseStorageTest: XCTestCase {
    var sut: InMemoryPassPhraseStorage!
    var passPhraseProvider: InMemoryPassPhraseProviderType!
    var timeoutInSeconds: Int!
    
    override func setUp() {
        passPhraseProvider = InMemoryPassPhraseProviderMock()
        timeoutInSeconds = 2
        sut = .init(
            passPhraseProvider: passPhraseProvider,
            timeoutInSeconds: timeoutInSeconds
        )
    }
    
    func testSavePassPhraseUpdatesDate() {
        let pass = PassPhrase(value: "A", fingerprints: ["11","12"])
        sut.save(passPhrase: pass)
        passPhraseProvider.passPhrases.forEach {
            XCTAssertNotNil($0.date)
        }
    }

    func testUpdatePassPhraseUpdatesDate() {
        let pass = PassPhrase(value: "A", fingerprints: ["11","12"])
        sut.update(passPhrase: pass)
        passPhraseProvider.passPhrases.forEach {
            XCTAssertNotNil($0.date)
        }
    }

    func testRemovePassPhrase() {
        let pass = PassPhrase(value: "A", fingerprints: ["11","12"])
        sut.save(passPhrase: pass)
        sut.remove(passPhrase: pass)
        XCTAssertTrue(passPhraseProvider.passPhrases.isEmpty)
    }
    
    func testGetPassPhrases() {
        XCTAssertTrue(sut.getPassPhrases().isEmpty)
        
        let pass = PassPhrase(value: "A", fingerprints: ["11","12"])
        sut.save(passPhrase: pass)
        XCTAssertTrue(sut.getPassPhrases().count == 1)
        XCTAssertTrue(sut.getPassPhrases().contains(where: { $0.primaryFingerprint == "11"}))
        XCTAssertTrue(sut.getPassPhrases().filter { $0.date == nil }.isEmpty)
    }
    
    func testExpiredPassPhrases() {
        XCTAssertTrue(sut.getPassPhrases().isEmpty)
        
        let pass = PassPhrase(value: "A", fingerprints: ["11","12"])
        sut.save(passPhrase: pass)
        sleep(3)
        XCTAssertTrue(sut.getPassPhrases().isEmpty)
    }
}


class InMemoryPassPhraseProviderMock: InMemoryPassPhraseProviderType {
    var passPhrases: Set<PassPhrase> = []
    
    func save(passPhrase: PassPhrase) {
        passPhrases.insert(passPhrase)
    }

    func remove(passPhrases passPhrasesToDelete: Set<PassPhrase>) {
        passPhrasesToDelete.forEach { passPhrases.remove($0) }
    }
}
