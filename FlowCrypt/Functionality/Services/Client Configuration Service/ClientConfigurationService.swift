//
//  OrganisationalRulesService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

protocol ClientConfigurationServiceType {
    func fetch(for user: User) async throws -> ClientConfiguration
    func getSaved(for user: String) -> ClientConfiguration
}

final class ClientConfigurationService {

    private let server: EnterpriseServerApiType
    private let local: LocalClientConfigurationType

    init(
        server: EnterpriseServerApiType = EnterpriseServerApi(),
        local: LocalClientConfigurationType
    ) {
        self.server = server
        self.local = local
    }
}

// MARK: - OrganisationalRulesServiceType
extension ClientConfigurationService: ClientConfigurationServiceType {

    func fetch(for user: User) async throws -> ClientConfiguration {
//        guard let user = user else {
//            throw AppErr.noCurrentUser
//        }
        do {
            let raw = try await server.getClientConfiguration(for: user.email)
            try local.save(for: user, raw: raw)
            return ClientConfiguration(raw: raw)
        } catch {
            guard let raw = local.load(for: user.email) else {
                throw error
            }
            return ClientConfiguration(raw: raw)
        }
    }

    func getSaved(for userEmail: String) -> ClientConfiguration {
        guard let raw = self.local.load(for: userEmail) else {
            // todo - throw instead
            fatalError("There should not be a user without OrganisationalRules")
        }
        return ClientConfiguration(raw: raw)
    }
}
