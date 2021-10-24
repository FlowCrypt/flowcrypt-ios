//
//  GeneralConstantsTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 21/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class GeneralConstantsTest: XCTestCase {
    func testGeneralGlobalConstants() {
        XCTAssert(GeneralConstants.Global.generalError == -1)
    }

    func testGeneralEmailConstants() {
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("Your FlowCrypt Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("Your CryptUp Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("Your CryptUP Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("CryptUP Account Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("All you need to know about CryptUP (contains a backup)"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.count == 5)
    }

    func testGmailConstants() {
        // Scope
        let currentScope: Set<String> = Set(GeneralConstants.Gmail.currentScope.map { $0.value })
        let expectedScope = Set([
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/",
            "https://www.googleapis.com/auth/contacts"
        ])
        XCTAssert(currentScope == expectedScope)

        // Client Id
        let clientId = GeneralConstants.Gmail.clientID
        XCTAssertTrue(clientId == "679326713487-5r16ir2f57bpmuh2d6dal1bcm9m1ffqc.apps.googleusercontent.com")
    }
}
