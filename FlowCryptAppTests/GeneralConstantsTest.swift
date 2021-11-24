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
        let mailScope: Set<String> = Set(GeneralConstants.Gmail.mailScope.map(\.value))
        let expectedMailScope = Set([
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/",
            "https://www.googleapis.com/auth/userinfo.email"
        ])
        XCTAssert(mailScope == expectedMailScope)

        let contactsScope: Set<String> = Set(GeneralConstants.Gmail.contactsScope.map(\.value))
        let expectedContactsScope = Set([
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/",
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/contacts",
            "https://www.googleapis.com/auth/contacts.other.readonly"
        ])
        XCTAssert(contactsScope == expectedContactsScope)

        // Client Id
        let clientId = GeneralConstants.Gmail.clientID
        XCTAssertTrue(clientId == "679326713487-5r16ir2f57bpmuh2d6dal1bcm9m1ffqc.apps.googleusercontent.com")
    }
}
