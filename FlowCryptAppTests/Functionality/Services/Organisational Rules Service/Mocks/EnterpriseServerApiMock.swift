//
//  EnterpriseServerApiMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 21.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises
@testable import FlowCrypt

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
    var getClientConfigurationCall: (String) -> (Result<ClientConfigurationWrapper, Error>) = { email in
        .failure(OrganisationalRulesServiceError.getClientConfigurationCall)
    }
    func getClientConfiguration(for email: String) -> Promise<ClientConfigurationWrapper> {
        getClientConfigurationInvoked = true
        getClientConfigurationCount += 1
        return Promise<ClientConfigurationWrapper>.resolveAfter(with: getClientConfigurationCall(email))
    }

    var getClientConfigurationForCurrentUserInvoked = false
    var getClientConfigurationForCurrentUserCount = 0
    var getClientConfigurationForCurrentUserCall: () -> (Result<ClientConfigurationWrapper, Error>) = {
        .failure(OrganisationalRulesServiceError.getClientConfigurationForCurrentUserCall)
    }
    func getClientConfigurationForCurrentUser() -> Promise<ClientConfigurationWrapper> {
        getClientConfigurationForCurrentUserInvoked = true
        getClientConfigurationForCurrentUserCount += 1
        return Promise<ClientConfigurationWrapper>.resolveAfter(with: getClientConfigurationForCurrentUserCall())
    }
}
