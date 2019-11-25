//
//  LocalStorageTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest

class LocalStorageTest: XCTestCase {
    var sut: LocalStorage!

    override func setUp() {
        sut = LocalStorage(userDefaults: UserDefaults.standard)
    }

    func test_save_user() {
        let user = User(email: "elonTesla@gmail.com", name: "ElonMask")
        sut.saveCurrent(user: user)
        let fetchedUser = sut.currentUser()

        XCTAssertNotNil(fetchedUser != nil)
        let expectationName = fetchedUser?.name == "ElonMask"
        XCTAssertTrue(expectationName)
         let expectationEmail = fetchedUser?.email == "elonTesla@gmail.com"
        XCTAssertTrue(expectationEmail)
    }

    func test_save_nil_for_user() {
        sut.saveCurrent(user: nil)
        let fetchedUser = sut.currentUser()
        XCTAssertNil(fetchedUser)
    }
}

