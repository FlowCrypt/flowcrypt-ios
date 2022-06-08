//
//  EmailKeyManagerApi.swift
//  FlowCryptAppTests
//
//  Created by Roma Sosnovsky on 07/06/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

final class EmailKeyManagerApiTests: XCTestCase {
    let core: Core! = .shared

    override func setUp() {
        let expectation = XCTestExpectation()
        Task {
            await core.startIfNotAlreadyRunning()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20)
    }

    func testValidKeyParsing() async throws {
        let service = EmailKeyManagerApi(clientConfiguration: .init(raw: .empty))
        let privateKey = DecryptedPrivateKeysResponse.DecryptedPrivateKey(
            decryptedPrivateKey: TestData.decryptedPrivateKey
        )
        let response = DecryptedPrivateKeysResponse(privateKeys: [privateKey])
        let validKeys = try await service.validate(decryptedPrivateKeysResponse: response)
        XCTAssertEqual(validKeys.count, 1)
    }

    func testInvalidKeyParsing() async throws {
        let service = EmailKeyManagerApi(clientConfiguration: .init(raw: .empty))
        let privateKey = DecryptedPrivateKeysResponse.DecryptedPrivateKey(
            decryptedPrivateKey: String(TestData.decryptedPrivateKey.prefix(200))
        )
        let response = DecryptedPrivateKeysResponse(privateKeys: [privateKey])

        do {
            _ = try await service.validate(decryptedPrivateKeysResponse: response)
            XCTFail("Invalid key parsing should throw")
        } catch {
            XCTAssertEqual(error as! EmailKeyManagerApiError, EmailKeyManagerApiError.keysAreInvalid)
        }
    }
}
