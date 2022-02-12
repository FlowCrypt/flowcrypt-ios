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
    func getSaved(for user: String) throws -> ClientConfiguration
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
        do {
            let raw = try await server.getClientConfiguration(for: user.email)
            let fesUrl = try await server.getActiveFesUrl(for: user.email)
            try local.save(for: user, raw: raw, fesUrl: fesUrl)
            return ClientConfiguration(raw: raw)
        } catch {
            guard let raw = try local.load(for: user.email) else {
                throw error
            }
            return ClientConfiguration(raw: raw)
        }
    }

    func getSaved(for userEmail: String) throws -> ClientConfiguration {
        guard let raw = try local.load(for: userEmail) else {
            // todo - throw instead
            fatalError("There should not be a user without OrganisationalRules")
        }
        return ClientConfiguration(raw: raw)
    }
}
