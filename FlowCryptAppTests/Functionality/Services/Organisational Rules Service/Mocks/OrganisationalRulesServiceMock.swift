//
//  OrganisationalRulesServiceMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 20.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises
@testable import FlowCrypt

class OrganisationalRulesServiceMock: ClientConfigurationServiceType {

    var fetchOrganisationalRulesForCurrentUserResult: Result<ClientConfiguration, Error> = .failure(MockError.some)
    func fetchClientConfigurationForCurrentUser() -> Promise<ClientConfiguration> {
        .resolveAfter(timeout: 1, with: fetchOrganisationalRulesForCurrentUserResult)
    }

    var fetchOrganisationalRulesForEmail: (String) -> (Result<ClientConfiguration, Error>) = { email in
        return .failure(MockError.some)
    }
    func fetchOrganisationalRules(for email: String) -> Promise<ClientConfiguration> {
        .resolveAfter(timeout: 1, with: fetchOrganisationalRulesForEmail(email))
    }

    var clientConfiguration: RawClientConfiguration!

    var getSavedOrganisationalRulesForCurrentUserResult: ClientConfiguration {
        ClientConfiguration(raw: clientConfiguration)
    }
    func getSavedClientConfigurationForCurrentUser() -> ClientConfiguration {
        getSavedOrganisationalRulesForCurrentUserResult
    }
}
