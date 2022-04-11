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
    var fetchOrganisationalRulesForCurrentUserResult: Result<ClientConfiguration, Error> = .failure(MockError())
    var configuration: ClientConfiguration {
        get async throws {
            switch fetchOrganisationalRulesForCurrentUserResult {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        }
    }

    func fetch(for user: User) async throws -> ClientConfiguration {
        throw MockError() // ??
    }

    var clientConfiguration: RawClientConfiguration!

    var getSavedOrganisationalRulesForCurrentUserResult: ClientConfiguration {
        ClientConfiguration(raw: clientConfiguration)
    }
    func getSaved(for user: String) -> ClientConfiguration {
        getSavedOrganisationalRulesForCurrentUserResult
    }
}
