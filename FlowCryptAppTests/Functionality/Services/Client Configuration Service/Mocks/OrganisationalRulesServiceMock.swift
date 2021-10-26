//
//  OrganisationalRulesServiceMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 20.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

final class OrganisationalRulesServiceMock: ClientConfigurationServiceType {

    var fetchOrganisationalRulesForCurrentUserResult: Result<ClientConfiguration, Error> = .failure(MockError.some)
    func fetchForCurrentUser() async throws -> ClientConfiguration {
        switch fetchOrganisationalRulesForCurrentUserResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    var fetchOrganisationalRulesForEmail: (String) throws -> ClientConfiguration = { _ in
        throw MockError.some
    }
    func fetchOrganisationalRules(for email: String) async throws -> ClientConfiguration {
        return try fetchOrganisationalRulesForEmail(email)
    }

    var clientConfiguration: RawClientConfiguration!

    var getSavedOrganisationalRulesForCurrentUserResult: ClientConfiguration {
        ClientConfiguration(raw: clientConfiguration)
    }
    func getSavedForCurrentUser() -> ClientConfiguration {
        getSavedOrganisationalRulesForCurrentUserResult
    }
}
