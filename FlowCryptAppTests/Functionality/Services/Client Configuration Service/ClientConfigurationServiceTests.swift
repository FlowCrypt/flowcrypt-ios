//
//  ClientConfigurationServiceTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 20.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

final class ClientConfigurationServiceTests: XCTestCase {

    var sut: ClientConfigurationService!
    var enterpriseServerApi: EnterpriseServerApiMock!
    var localClientConfigurationProvider: LocalClientConfigurationMock!
    var isCurrentUserExistMock: CurrentUserEmailMock!
    let user = User(email: "example@flowcrypt.test", isActive: true, name: "User", imap: nil, smtp: nil)

    override func setUp() {
        super.setUp()
        enterpriseServerApi = EnterpriseServerApiMock()
        localClientConfigurationProvider = LocalClientConfigurationMock()
        isCurrentUserExistMock = CurrentUserEmailMock()

        sut = ClientConfigurationService(
            server: enterpriseServerApi,
            local: localClientConfigurationProvider
        )
    }

    func testGetSavedOrganisationalRulesForCurrentUser() async throws {
        let expectedConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")
        enterpriseServerApi.getClientConfigurationCall = { _ in
            expectedConfiguration
        }

        let clientConfiguration = try await sut.configuration
        XCTAssert(localClientConfigurationProvider.fetchCount == 1)
        XCTAssert(localClientConfigurationProvider.fetchInvoked == true)
        XCTAssert(clientConfiguration.raw == expectedConfiguration)
    }

    func testFetchOrganisationalRulesForCurrentUserNil() async {
        isCurrentUserExistMock.currentUserEmailCall = {
            nil
        }
        do {
            _ = try await sut.configuration
            XCTFail()
        } catch {}
    }

    func testFetchOrganisationalRulesForCurrentUser() async throws {
        let expectedClientConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        enterpriseServerApi.getClientConfigurationCall = { email in
            XCTAssertTrue(email == "example@flowcrypt.test")
            return expectedClientConfiguration
        }

        localClientConfigurationProvider.saveCall = { clientConfiguration in
            XCTAssertTrue(clientConfiguration.keyManagerUrl == expectedClientConfiguration.keyManagerUrl)
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }

        _ = try await sut.configuration
    }

    func testInCaseGetClientConfigurationReturnsError() async throws {
        let expectedClientConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        enterpriseServerApi.getClientConfigurationCall = { email in
            throw MockError()
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }

        localClientConfigurationProvider.raw = expectedClientConfiguration

        let clientConfiguration = try await sut.configuration
        XCTAssertTrue(clientConfiguration.raw == expectedClientConfiguration)
    }
}

enum OrganisationalRulesServiceError: Error {
    case getActiveFesUrlCall
    case getActiveFesUrlForCurrentUserCall
    case getClientConfigurationCall
    case getClientConfigurationForCurrentUserCall
}
