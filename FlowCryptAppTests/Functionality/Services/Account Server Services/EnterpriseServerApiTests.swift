//
//  EnterpriseServerApiTests.swift
//  FlowCryptAppTests
//
//  Created by  Ivan Ushakov on 04.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

final class EnterpriseServerApiTests: XCTestCase {

    func testGetActiveFesUrlWithUnknownDomain() async throws {
        // arrange
        let service = EnterpriseServerApi()

        // act
        let result = try await service.getActiveFesUrl(for: "user@nonexistentdomain.test")

        // assert
        XCTAssertNil(result)
    }

    func testGetClientConfigurationWithoutActiveFesUrl() async throws {
        // arrange
        let service = EnterpriseServerApi()

        // act
        let result = try await service.getClientConfiguration(for: "user@gmail.com")

        // assert
        XCTAssertEqual(result, .empty)
    }
}
