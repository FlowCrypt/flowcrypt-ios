//
//  LocalStorageTests.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 27.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

class LocalStorageTests: XCTestCase {
    var sut: LocalStorage!

    override func setUp() {
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

    func testLogOutForUser() throws {
        let user = "anton@gmail.com"
        try sut.logOutUser(email: user)
        XCTAssertNil(UserDefaults.standard.string(forKey: trashKey))
    }
}
