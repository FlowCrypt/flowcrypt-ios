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
        let expectation = XCTestExpectation(
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

        let expectations: [XCTestExpectation] = [
            expectation,
            getClientConfigurationInvokedExpectation,
            getClientConfigurationCountExpectation,
            getClientConfigurationCallExpectation,
            clientConfigurationProviderSaveCall
        ]

        let expectedClientConfiguration = ClientConfiguration(keyManagerUrl: "https://ekm.example.com")

        // (String) -> (Result<ClientConfiguration, Error>)
        self.enterpriseServerApi.getClientConfigurationCall = { email in
            if email == "example@flowcrypt.test" {
                getClientConfigurationCallExpectation.fulfill()
            }
            // TODO: - ANTON - test for error
            return Result<ClientConfiguration, Error>.success(expectedClientConfiguration)
        }

        // (ClientConfiguration) -> (Void)
        self.clientConfigurationProvider.saveCall = { clientConfiguration in
            // TODO: - ANTON - test in case wrong config fetched
            if clientConfiguration.keyManagerUrl == expectedClientConfiguration.keyManagerUrl {
                clientConfigurationProviderSaveCall.fulfill()
            }
        }

        isCurrentUserExistMock.currentUserEmailCall = {
            "example@flowcrypt.test"
        }
        sut.fetchOrganisationalRulesForCurrentUser()
            .then(on: .main) { _ -> Promise<OrganisationalRules> in
                expectation.fulfill()

                // test calls for enterpriseServerApi
                if self.enterpriseServerApi.getClientConfigurationInvoked {
                    getClientConfigurationInvokedExpectation.fulfill()
                }
                if self.enterpriseServerApi.getClientConfigurationCount == 1 {
                    getClientConfigurationCountExpectation.fulfill()
                }


                // test calls for clientConfigurationProvider
                if self.clientConfigurationProvider.saveInvoked {

                }
                if self.clientConfigurationProvider.saveCount == 1 {

                }


                let result: Result<OrganisationalRules, MockError> = .failure(.some)
                return Promise<OrganisationalRules>.resolveAfter(with: result)
            }
            .catch(on: .main) { error in
                XCTFail()
            }

        wait(for: expectations, timeout: 1)
    }
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
        .failure(MockError.some)
    }
    func getActiveFesUrl(for email: String) -> Promise<String?> {
        getActiveFesUrlInvoked = true
        getActiveFesUrlInvokedCount += 1
        return Promise<String?>.resolveAfter(with: getActiveFesUrlCall(email))
    }

    var getActiveFesUrlForCurrentUserInvoked = false
    var getActiveFesUrlForCurrentUserCount = 0
    var getActiveFesUrlForCurrentUserCall: () -> (Result<String?, Error>) = {
        .failure(MockError.some)
    }
    func getActiveFesUrlForCurrentUser() -> Promise<String?> {
        getActiveFesUrlForCurrentUserInvoked = true
        getActiveFesUrlForCurrentUserCount += 1
        return Promise<String?>.resolveAfter(with: getActiveFesUrlForCurrentUserCall())
    }

    var getClientConfigurationInvoked = false
    var getClientConfigurationCount = 0
    var getClientConfigurationCall: (String) -> (Result<ClientConfiguration, Error>) = { email in
        .failure(MockError.some)
    }
    func getClientConfiguration(for email: String) -> Promise<ClientConfiguration> {
        getClientConfigurationInvoked = true
        getClientConfigurationCount += 1
        return Promise<ClientConfiguration>.resolveAfter(with: getClientConfigurationCall(email))
    }

    var getClientConfigurationForCurrentUserInvoked = false
    var getClientConfigurationForCurrentUserCount = 0
    var getClientConfigurationForCurrentUserCall: () -> (Result<ClientConfiguration, Error>) = {
        .failure(MockError.some)
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
