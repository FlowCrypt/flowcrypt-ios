//
//  GmailServiceTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 23.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import GTMAppAuth
import XCTest

class GmailServiceTest: XCTestCase {

    var sut: GmailService!
    var authManager: GoogleAuthManagerMock!

    override func setUp() {
        authManager = GoogleAuthManagerMock()
        sut = GmailService(
            currentUserEmail: "user@example.test",
            googleAuthManager: authManager
        )
    }

    func testMakeBackupQuery() async {
        let backupQuery = sut.makeBackupQuery(acctEmail: "james.bond@gmail.com")
        let expectedQuery =
            "from:james.bond@gmail.com to:james.bond@gmail.com " +
            "subject:\"Your FlowCrypt Backup\" OR " +
            "subject:\"Your CryptUp Backup\" OR " +
            "subject:\"All you need to know about CryptUP (contains a backup)\" OR " +
            "subject:\"CryptUP Account Backup\" " +
            "-is:spam"
        XCTAssertEqual(backupQuery, expectedQuery)
    }
}

// MARK: - Mock
class GoogleAuthManagerMock: GoogleAuthManagerType {
    func authorization(for email: String?) -> GTMAppAuthFetcherAuthorization? {
        return nil
    }

    var isContactsScopeEnabled = true
    func searchContacts(query: String) async throws -> [Recipient] {
        return []
    }
}
