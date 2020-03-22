//
//  GeneralConstantsTest.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 21/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import XCTest

class GeneralConstantsTest: XCTestCase {

    func test_general_global_constants() {
        XCTAssert(GeneralConstants.Global.generalError == -1)
        XCTAssert(GeneralConstants.Global.gmailRootPath == "[Gmail]")
        XCTAssert(GeneralConstants.Global.gmailAllMailPath == "[Gmail]/All Mail")
    }

    func test_general_email_constants() {
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("Your FlowCrypt Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("Your CryptUp Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("Your CryptUP Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("CryptUP Account Backup"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.contains("All you need to know about CryptUP (contains a backup)"))
        XCTAssert(GeneralConstants.EmailConstant.recoverAccountSearchSubject.count == 5)
    }
}
