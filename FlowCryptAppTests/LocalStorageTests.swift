//
//  LocalStorageTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 27.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class LocalStorageTests: XCTestCase {
    var sut: LocalStorage!
    let testPassPhraseAccount = "passphrase@account.test"

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = LocalStorage()
    }

    var trashKey: String {
        "indexTrashFolder"
    }

    func testSaveTrashFolder() {
        let somePath = "dummyPath/gmail/trash"
        sut.saveTrashFolder(path: somePath)
        XCTAssertTrue(UserDefaults.standard.string(forKey: trashKey) == somePath)
    }
}
