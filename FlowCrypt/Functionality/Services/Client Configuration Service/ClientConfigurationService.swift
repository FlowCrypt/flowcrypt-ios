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
    func fetchForCurrentUser() async throws -> ClientConfiguration
    func getSavedForCurrentUser() -> ClientConfiguration
}

final class ClientConfigurationService {

    private let server: EnterpriseServerApiType
    private let local: LocalClientConfigurationType
    private let getCurrentUserEmail: () -> (String?)

    init(
        server: EnterpriseServerApiType = EnterpriseServerApi(),
        local: LocalClientConfigurationType = LocalClientConfiguration(),
        getCurrentUserEmail: @autoclosure @escaping () -> (String?) =  DataService.shared.currentUser?.email
    ) {
        self.server = server
        self.local = local
        self.getCurrentUserEmail = getCurrentUserEmail
    }
}

// MARK: - OrganisationalRulesServiceType
extension ClientConfigurationService: ClientConfigurationServiceType {

    func fetchForCurrentUser() async throws -> ClientConfiguration {
        guard let currentUserEmail = getCurrentUserEmail() else {
            throw AppErr.noCurrentUser
        }
        do {
            let raw = try await server.getClientConfiguration(for: currentUserEmail)
            local.save(raw: raw)
            return ClientConfiguration(raw: raw)
        } catch {
            guard let raw = local.load() else {
                throw error
            }
            return ClientConfiguration(raw: raw)
        }
    }

    func getSavedForCurrentUser() -> ClientConfiguration {
        guard let raw = self.local.load() else {
            fatalError("There should not be a user without OrganisationalRules")
        }

        return ClientConfiguration(raw: raw)
    }
}
