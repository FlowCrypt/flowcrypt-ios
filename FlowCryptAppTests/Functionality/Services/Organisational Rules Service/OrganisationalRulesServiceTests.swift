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

    var sut: OrganisationalRulesService!
    var enterpriseServerApi: EnterpriseServerApiMock!
    var clientConfigurationProvider: ClientConfigurationProviderMock!
    var isCurrentUserExistMock: CurrentUserEmailMock!

    override func setUp() {
        super.setUp()
        enterpriseServerApi = EnterpriseServerApiMock()
        clientConfigurationProvider = ClientConfigurationProviderMock()
        isCurrentUserExistMock = CurrentUserEmailMock()

        sut = OrganisationalRulesService(
            enterpriseServerApi: enterpriseServerApi,
            clientConfigurationProvider: clientConfigurationProvider,
            isCurrentUserExist: self.isCurrentUserExistMock.currentUserEmail()
        )

        DispatchQueue.promises = .global()
    }

    func testGetSavedOrganisationalRulesForCurrentUser() {
        let expectedConfiguration = ClientConfiguration(keyManagerUrl: "https://ekm.example.com")
        clientConfigurationProvider.fetchCall = {
            expectedConfiguration
        }

        let organisationalRules = sut.getSavedOrganisationalRulesForCurrentUser()
        XCTAssert(clientConfigurationProvider.fetchCount == 1)
        XCTAssert(clientConfigurationProvider.fetchInvoked == true)
        XCTAssert(organisationalRules.clientConfiguration == expectedConfiguration)
    }

    func testFetchOrganisationalRulesForCurrentUserNil() {
        let expectation = XCTestExpectation(description: "Promise should resolve with error if current user = nil")
        isCurrentUserExistMock.currentUserEmailCall = {
            nil
        }
        sut.fetchOrganisationalRulesForCurrentUser()
            .then(on: .main) { _ -> Promise<OrganisationalRules> in
                XCTFail()
                let result: Result<OrganisationalRules, MockError> = .failure(.some)
                return Promise<OrganisationalRules>.resolveAfter(with: result)
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

        let expectedClientConfiguration = ClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        // (String) -> (Result<ClientConfiguration, Error>)
        self.enterpriseServerApi.getClientConfigurationCall = { email in
            if email == "example@flowcrypt.test" {
                getClientConfigurationCallExpectation.fulfill()
            }
            return Result<ClientConfiguration, Error>.success(expectedClientConfiguration)
        }

        // (ClientConfiguration) -> (Void)
        self.clientConfigurationProvider.saveCall = { clientConfiguration in
            if clientConfiguration.keyManagerUrl == expectedClientConfiguration.keyManagerUrl {
                clientConfigurationProviderSaveCall.fulfill()
            }
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }
        
        sut.fetchOrganisationalRulesForCurrentUser()
            .then(on: .main) { orgRules -> Promise<OrganisationalRules> in
                fetchOrganisationalRulesExpectation.fulfill()

                // test calls for enterpriseServerApi
                if self.enterpriseServerApi.getClientConfigurationInvoked {
                    getClientConfigurationInvokedExpectation.fulfill()
                }
                if self.enterpriseServerApi.getClientConfigurationCount == 1 {
                    getClientConfigurationCountExpectation.fulfill()
                }
                if self.clientConfigurationProvider.saveCount == 1 {
                    clientConfigurationProviderSaveCountCall.fulfill()
                }

                let result: Result<OrganisationalRules, MockError> = .success(orgRules)
                return Promise<OrganisationalRules>.resolveAfter(with: result)
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

        let expectedClientConfiguration = ClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        self.enterpriseServerApi.getClientConfigurationCall = { email in
            .failure(MockError.some)
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }

        clientConfigurationProvider.fetchCall = {
            expectedClientConfiguration
        }

        sut.fetchOrganisationalRulesForCurrentUser()
            .then(on: .main) { organisationalRules -> Promise<OrganisationalRules> in
                if organisationalRules.clientConfiguration == expectedClientConfiguration {
                    fetchOrganisationalRulesForCurrentUserExpectation.fulfill()
                }
                let result: Result<OrganisationalRules, Error> = .success(organisationalRules)
                return Promise<OrganisationalRules>.resolveAfter(with: result)
            }
            .recover { error -> Promise<OrganisationalRules> in
                let result: Result<OrganisationalRules, Error> = .success(OrganisationalRules(clientConfiguration: expectedClientConfiguration))
                return Promise<OrganisationalRules>.resolveAfter(with: result)
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
