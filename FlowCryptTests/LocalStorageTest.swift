//
//  LocalStorageTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import XCTest

class LocalStorageTest: XCTestCase {
    var localStorage: LocalStorage!

    override func setUp() {
        localStorage = LocalStorage()
    }

    func test_save_user() {
        let user = User(email: "elonTesla@gmail.com", name: "ElonMask")
        localStorage.saveCurrentUser(user: user)
        let fetchedUser = localStorage.currentUser()

        XCTAssertNotNil(fetchedUser != nil)
        let expectationName = fetchedUser?.name == "ElonMask"
        XCTAssertTrue(expectationName)
        let expectationEmail = fetchedUser?.email == "elonTesla@gmail.com"
        XCTAssertTrue(expectationEmail)
    }

    func test_save_nil_for_user() {
        localStorage.saveCurrentUser(user: nil)
        let fetchedUser = localStorage.currentUser()
        XCTAssertNil(fetchedUser)
    }
}
