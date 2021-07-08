//
//  GmailServiceTest.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 23.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
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
    
    func testSearchBackupsWhenErrorInQuery() {
        backupSearchQueryProvider.makeBackupQueryResult = .failure(.some)
        let expectation = XCTestExpectation()
        
        sut.searchBackups(for: "james.bond@gmail.com")
            .then(on: .main) { data in
                
            }
            .catch(on: .main) { error in
                switch error as? GmailServiceError {
                case .missedBackupQuery(let underliningError):
                    if underliningError is MockError {
                        expectation.fulfill()
                    }
                default:
                    break
                }
            }
        wait(for: [expectation], timeout: 3, enforceOrder: true)
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
