//
//  GmailServiceTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 23.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
import Promises
import GTMAppAuth
@testable import FlowCrypt

class GmailServiceTest: XCTestCase {

    var sut: GmailService!
    var userService: GoogleUserServiceMock!
    var backupSearchQueryProvider: GmailBackupSearchQueryProviderMock!

    override func setUp() {
        userService = GoogleUserServiceMock()
        backupSearchQueryProvider = GmailBackupSearchQueryProviderMock()
        sut = GmailService(userService: userService, backupSearchQueryProvider: backupSearchQueryProvider)
    }

    func testSearchBackupsWhenErrorInQuery() async {
        backupSearchQueryProvider.makeBackupQueryResult = .failure(.some)

        do {
            _ = try await sut.searchBackups(for: "james.bond@gmail.com")
        } catch {
            switch error as? GmailServiceError {
            case .missedBackupQuery(let underliningError):
                XCTAssertTrue(underliningError is MockError)
            default:
                XCTFail()
            }
        }
    }
}

// MARK: - Mock
class GoogleUserServiceMock: GoogleUserServiceType {
    var authorization: GTMAppAuthFetcherAuthorization? = nil
    
    var renewSessionResult: Result<Void, Error> = .success(())
    func renewSession() -> Promise<Void> {
        Promise<Void>.resolveAfter(timeout: 1, with: renewSessionResult)
    }
}

class GmailBackupSearchQueryProviderMock: GmailBackupSearchQueryProviderType {
    var makeBackupQueryResult: Result<String, MockError> = .success("query")
    func makeBackupQuery(for email: String) throws -> String {
        try makeBackupQueryResult.get()
    }
}
