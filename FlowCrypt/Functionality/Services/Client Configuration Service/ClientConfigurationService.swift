//
//  OrganisationalRulesService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import Promises

protocol ClientConfigurationServiceType {
    func fetchClientConfigurationForCurrentUser() -> Promise<ClientConfiguration>
    func getSavedClientConfigurationForCurrentUser() -> ClientConfiguration
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

    func fetchClientConfigurationForCurrentUser() -> Promise<ClientConfiguration> {
        guard let currentUserEmail = getCurrentUserEmail() else {
            return Promise<ClientConfiguration> { _, reject in
                reject(ClientConfigurationServiceError.noCurrentUser)
            }
        }
        return Promise<ClientConfiguration> { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            let raw = try awaitPromise(
                self.server.getClientConfiguration(for: currentUserEmail)
            )
            self.local.save(raw: raw)
            resolve(ClientConfiguration(raw: raw))
        }
        .recover { [weak self] error -> ClientConfiguration in
            guard let self = self else { throw AppErr.nilSelf }
            guard let raw = self.local.load() else {
                throw error
            }
            return ClientConfiguration(raw: raw)
        }
    }


    func getSavedClientConfigurationForCurrentUser() -> ClientConfiguration {
        guard let raw = self.local.load() else {
            fatalError("There should not be a user without OrganisationalRules")
        }

        return ClientConfiguration(raw: raw)
    }
}
