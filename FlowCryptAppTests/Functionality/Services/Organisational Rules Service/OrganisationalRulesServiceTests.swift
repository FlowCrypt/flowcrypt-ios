//
//  OrganisationalRulesServiceTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 20.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
import Promises
@testable import FlowCrypt

class OrganisationalRulesServiceTests: XCTestCase {

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

        let clientConfiguration = sut.getSavedClientConfigurationForCurrentUser()
        XCTAssert(localClientConfigurationProvider.fetchCount == 1)
        XCTAssert(localClientConfigurationProvider.fetchInvoked == true)
        XCTAssert(clientConfiguration.raw == expectedConfiguration)
    }

    func testFetchOrganisationalRulesForCurrentUserNil() {
        let expectation = XCTestExpectation(description: "Promise should resolve with error if current user = nil")
        isCurrentUserExistMock.currentUserEmailCall = {
            nil
        }
        sut.fetchClientConfigurationForCurrentUser()
            .then(on: .main) { _ -> Promise<ClientConfiguration> in
                XCTFail()
                let result: Result<ClientConfiguration, MockError> = .failure(.some)
                return Promise<ClientConfiguration>.resolveAfter(with: result)
            }
            .catch(on: .main) { error in
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1)
    }

    func testFetchOrganisationalRulesForCurrentUser() {
        let fetchOrganisationalRulesExpectation = XCTestExpectation(
            description: "fetchOrganisationalRules for test email should be called"
        )
        let getClientConfigurationInvokedExpectation = XCTestExpectation(
            description: "getClientConfiguration should be called"
        )
        let getClientConfigurationCountExpectation = XCTestExpectation(
            description: "getClientConfiguration should be called"
        )
        let getClientConfigurationCallExpectation = XCTestExpectation(
            description: "getClientConfiguration should be called for test email"
        )
        let clientConfigurationProviderSaveCall = XCTestExpectation(
            description: "clientConfigurationProvider save method should be called for config"
        )
        let clientConfigurationProviderSaveCountCall = XCTestExpectation(
            description: "clientConfigurationProvider save method should be called for config"
        )

        let expectations: [XCTestExpectation] = [
            fetchOrganisationalRulesExpectation,
            getClientConfigurationInvokedExpectation,
            getClientConfigurationCountExpectation,
            getClientConfigurationCallExpectation,
            clientConfigurationProviderSaveCall,
            clientConfigurationProviderSaveCountCall
        ]

        let expectedClientConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        // (String) -> (Result<ClientConfiguration, Error>)
        self.enterpriseServerApi.getClientConfigurationCall = { email in
            if email == "example@flowcrypt.test" {
                getClientConfigurationCallExpectation.fulfill()
            }
            return Result<RawClientConfiguration, Error>.success(expectedClientConfiguration)
        }

        // (ClientConfiguration) -> (Void)
        self.localClientConfigurationProvider.saveCall = { clientConfiguration in
            if clientConfiguration.keyManagerUrl == expectedClientConfiguration.keyManagerUrl {
                clientConfigurationProviderSaveCall.fulfill()
            }
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }
        
        sut.fetchClientConfigurationForCurrentUser()
            .then(on: .main) { orgRules -> Promise<ClientConfiguration> in
                fetchOrganisationalRulesExpectation.fulfill()

                // test calls for enterpriseServerApi
                if self.enterpriseServerApi.getClientConfigurationInvoked {
                    getClientConfigurationInvokedExpectation.fulfill()
                }
                if self.enterpriseServerApi.getClientConfigurationCount == 1 {
                    getClientConfigurationCountExpectation.fulfill()
                }
                if self.localClientConfigurationProvider.saveCount == 1 {
                    clientConfigurationProviderSaveCountCall.fulfill()
                }

                let result: Result<ClientConfiguration, MockError> = .success(orgRules)
                return Promise<ClientConfiguration>.resolveAfter(with: result)
            }
            .catch(on: .main) { error in
                XCTFail()
            }

        wait(for: expectations, timeout: 1)
    }

    func testInCaseGetClientConfigurationReturnsError() {
        let fetchOrganisationalRulesForCurrentUserExpectation = XCTestExpectation()

        let expectations = [
            fetchOrganisationalRulesForCurrentUserExpectation
        ]

        let expectedClientConfiguration = RawClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        self.enterpriseServerApi.getClientConfigurationCall = { email in
            .failure(MockError.some)
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }

        localClientConfigurationProvider.fetchCall = {
            expectedClientConfiguration
        }

        sut.fetchClientConfigurationForCurrentUser()
            .then(on: .main) { clientConfiguration -> Promise<ClientConfiguration> in
                if clientConfiguration.raw == expectedClientConfiguration {
                    fetchOrganisationalRulesForCurrentUserExpectation.fulfill()
                }
                let result: Result<ClientConfiguration, Error> = .success(clientConfiguration)
                return Promise<ClientConfiguration>.resolveAfter(with: result)
            }
            .recover { error -> Promise<ClientConfiguration> in
                let result: Result<ClientConfiguration, Error> = .success(ClientConfiguration(raw: expectedClientConfiguration))
                return Promise<ClientConfiguration>.resolveAfter(with: result)
            }
        wait(for: expectations, timeout: 1)
    }
}

enum OrganisationalRulesServiceError: Error {
    case getActiveFesUrlCall
    case getActiveFesUrlForCurrentUserCall
    case getClientConfigurationCall
    case getClientConfigurationForCurrentUserCall
} 
