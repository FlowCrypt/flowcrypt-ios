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

    func testGetClientConfigurationWithUnknownDomain() async throws {
        let service = try EnterpriseServerApi(email: "user@nonexistentdomain.test")
        let configuration = try await service.getClientConfiguration()
        XCTAssertEqual(configuration, .empty)
    }

    func testGetClientConfigurationWithoutActiveFesUrl() async throws {
        let service = try EnterpriseServerApi(email: "user@gmail.com")
        let configuration = try await service.getClientConfiguration()
        XCTAssertEqual(configuration, .empty)
    }
}
