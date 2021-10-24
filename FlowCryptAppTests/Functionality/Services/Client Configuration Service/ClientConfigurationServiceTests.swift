//
//  ClientConfigurationServiceTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 20.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
@testable import FlowCrypt

final class ClientConfigurationServiceTests: XCTestCase {

    var sut: ClientConfigurationService!
    var enterpriseServerApi: EnterpriseServerApiMock!
    var localClientConfigurationProvider: LocalClientConfigurationMock!
    var isCurrentUserExistMock: CurrentUserEmailMock!

    override func setUp() {
        super.setUp()
        enterpriseServerApi = EnterpriseServerApiMock()
        localClientConfigurationProvider = LocalClientConfigurationMock()
        isCurrentUserExistMock = CurrentUserEmailMock()

        sut = ClientConfigurationService(
            server: enterpriseServerApi,
            local: localClientConfigurationProvider,
            getCurrentUserEmail: self.isCurrentUserExistMock.currentUserEmail()
        )

        DispatchQueue.promises = .global()
    }

    func testGetSavedOrganisationalRulesForCurrentUser() {
        let expectedConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")
        localClientConfigurationProvider.fetchCall = {
            expectedConfiguration
        }

        let clientConfiguration = sut.getSavedForCurrentUser()
        XCTAssert(localClientConfigurationProvider.fetchCount == 1)
        XCTAssert(localClientConfigurationProvider.fetchInvoked == true)
        XCTAssert(clientConfiguration.raw == expectedConfiguration)
    }

    func testFetchOrganisationalRulesForCurrentUserNil() async {
        isCurrentUserExistMock.currentUserEmailCall = {
            nil
        }
        do {
            _ = try await sut.fetchForCurrentUser()
            XCTFail()
        } catch {
        }
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

        _ = try await sut.fetchForCurrentUser()
    }

    func testInCaseGetClientConfigurationReturnsError() async throws {
        let expectedClientConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        enterpriseServerApi.getClientConfigurationCall = { email in
            throw MockError.some
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }

        localClientConfigurationProvider.fetchCall = {
            expectedClientConfiguration
        }

        let clientConfiguration = try await sut.fetchForCurrentUser()
        XCTAssertTrue(clientConfiguration.raw == expectedClientConfiguration)
    }
}

enum OrganisationalRulesServiceError: Error {
    case getActiveFesUrlCall
    case getActiveFesUrlForCurrentUserCall
    case getClientConfigurationCall
    case getClientConfigurationForCurrentUserCall
} 
