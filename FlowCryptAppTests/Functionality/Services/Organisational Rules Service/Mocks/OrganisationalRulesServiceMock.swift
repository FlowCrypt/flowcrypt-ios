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

class OrganisationalRulesServiceMock: OrganisationalRulesServiceType {

    var fetchOrganisationalRulesForCurrentUserResult: Result<OrganisationalRules, Error> = .failure(MockError.some)
    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules> {
        .resolveAfter(timeout: 1, with: fetchOrganisationalRulesForCurrentUserResult)
    }

    var fetchOrganisationalRulesForEmail: (String) -> (Result<OrganisationalRules, Error>) = { email in
        return .failure(MockError.some)
    }
    func fetchOrganisationalRules(for email: String) -> Promise<OrganisationalRules> {
        .resolveAfter(timeout: 1, with: fetchOrganisationalRulesForEmail(email))
    }

    var clientConfiguration: ClientConfigurationWrapper!

    var getSavedOrganisationalRulesForCurrentUserResult: OrganisationalRules {
        OrganisationalRules(clientConfiguration: clientConfiguration)
    }
    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules {
        getSavedOrganisationalRulesForCurrentUserResult
    }
}
