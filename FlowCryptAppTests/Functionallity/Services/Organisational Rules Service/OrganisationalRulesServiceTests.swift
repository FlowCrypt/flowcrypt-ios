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
