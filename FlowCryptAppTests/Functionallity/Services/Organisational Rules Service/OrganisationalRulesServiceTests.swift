//
//  OrganisationalRulesServiceTests.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 20.09.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
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

class CurrentUserEmailMock {
    var currentUserEmailCall: () -> (String?) = {
        nil
    }
    func currentUserEmail() -> String? {
        currentUserEmailCall()
    }
}

class EnterpriseServerApiMock: EnterpriseServerApiType {
    var getActiveFesUrlInvoked = false
    var getActiveFesUrlInvokedCount = 0
    var getActiveFesUrlCall: (String) -> (Result<String?, Error>) = { email in
        .failure(OrganisationalRulesServiceError.getActiveFesUrlCall)
    }
    func getActiveFesUrl(for email: String) -> Promise<String?> {
        getActiveFesUrlInvoked = true
        getActiveFesUrlInvokedCount += 1
        return Promise<String?>.resolveAfter(with: getActiveFesUrlCall(email))
    }

    var getActiveFesUrlForCurrentUserInvoked = false
    var getActiveFesUrlForCurrentUserCount = 0
    var getActiveFesUrlForCurrentUserCall: () -> (Result<String?, Error>) = {
        .failure(OrganisationalRulesServiceError.getActiveFesUrlForCurrentUserCall)
    }
    func getActiveFesUrlForCurrentUser() -> Promise<String?> {
        getActiveFesUrlForCurrentUserInvoked = true
        getActiveFesUrlForCurrentUserCount += 1
        return Promise<String?>.resolveAfter(with: getActiveFesUrlForCurrentUserCall())
    }

    var getClientConfigurationInvoked = false
    var getClientConfigurationCount = 0
    var getClientConfigurationCall: (String) -> (Result<ClientConfiguration, Error>) = { email in
        .failure(OrganisationalRulesServiceError.getClientConfigurationCall)
    }
    func getClientConfiguration(for email: String) -> Promise<ClientConfiguration> {
        getClientConfigurationInvoked = true
        getClientConfigurationCount += 1
        return Promise<ClientConfiguration>.resolveAfter(with: getClientConfigurationCall(email))
    }

    var getClientConfigurationForCurrentUserInvoked = false
    var getClientConfigurationForCurrentUserCount = 0
    var getClientConfigurationForCurrentUserCall: () -> (Result<ClientConfiguration, Error>) = {
        .failure(OrganisationalRulesServiceError.getClientConfigurationForCurrentUserCall)
    }
    func getClientConfigurationForCurrentUser() -> Promise<ClientConfiguration> {
        getClientConfigurationForCurrentUserInvoked = true
        getClientConfigurationForCurrentUserCount += 1
        return Promise<ClientConfiguration>.resolveAfter(with: getClientConfigurationForCurrentUserCall())
    }
}

class ClientConfigurationProviderMock: ClientConfigurationProviderType {
    var fetchInvoked = false
    var fetchCount = 0
    var fetchCall: () -> (ClientConfiguration?) = {
        nil
    }
    func fetch() -> ClientConfiguration? {
        fetchInvoked = true
        fetchCount += 1
        return fetchCall()
    }

    var removeClientConfigurationInvoked = false
    var removeClientConfigurationCount = 0
    func removeClientConfiguration() {
        removeClientConfigurationInvoked = true
        removeClientConfigurationCount += 1
    }

    var saveInvoked = false
    var saveCount = 0
    var saveCall: (ClientConfiguration) -> (Void) = { clientConfiguration in

    }
    func save(clientConfiguration: ClientConfiguration) {
        saveInvoked = true
        saveCount += 1
        saveCall(clientConfiguration)
    }
}
