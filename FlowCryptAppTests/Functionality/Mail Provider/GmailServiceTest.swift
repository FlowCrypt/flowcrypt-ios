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
    var backupSearchQueryProvider: GmailBackupSearchQueryProviderMock!

    override func setUp() {
        authManager = GoogleAuthManagerMock()
        backupSearchQueryProvider = GmailBackupSearchQueryProviderMock()
        sut = GmailService(
            currentUserEmail: "user@example.test",
            googleAuthManager: authManager,
            backupSearchQueryProvider: backupSearchQueryProvider
        )
    }

    func testSearchBackupsWhenErrorInQuery() async {
        backupSearchQueryProvider.makeBackupQueryResult = .failure(MockError())

        do {
            _ = try await sut.searchBackups(for: "james.bond@gmail.com")
        } catch {
            switch error as? GmailApiError {
            case let .missingBackupQuery(underliningError):
                XCTAssertTrue(underliningError is MockError)
            default:
                XCTFail()
            }
        }
    }
}

// MARK: - Mock
class GoogleAuthManagerMock: GoogleAuthManagerType {
    var authorization: GTMAppAuthFetcherAuthorization?
    func renewSession() async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    var isContactsScopeEnabled = true
    func searchContacts(query: String) async throws -> [Recipient] {
        return []
    }
}

class GmailBackupSearchQueryProviderMock: GmailBackupSearchQueryProviderType {
    var makeBackupQueryResult: Result<String, MockError> = .success("query")
    func makeBackupQuery(for email: String) throws -> String {
        try makeBackupQueryResult.get()
    }
}
