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

protocol OrganisationalRulesServiceType {
    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules>
    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules
}

final class OrganisationalRulesService {

    private let enterpriseServerApi: EnterpriseServerApiType
    private let clientConfigurationProvider: ClientConfigurationProviderType
    private let isCurrentUserExist: () -> (String?)

    init(
        enterpriseServerApi: EnterpriseServerApiType = EnterpriseServerApi(),
        clientConfigurationProvider: ClientConfigurationProviderType = ClientConfigurationProvider(),
        isCurrentUserExist: @autoclosure @escaping () -> (String?) =  DataService.shared.currentUser?.email
    ) {
        self.enterpriseServerApi = enterpriseServerApi
        self.clientConfigurationProvider = clientConfigurationProvider
        self.isCurrentUserExist = isCurrentUserExist
    }
}

// MARK: - OrganisationalRulesServiceType
extension OrganisationalRulesService: OrganisationalRulesServiceType {

    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules> {
        guard let currentUserEmail = isCurrentUserExist() else {
            return Promise<OrganisationalRules> { _, reject in
                reject(OrganisationalRulesServiceError.noCurrentUser)
            }
        }
        return fetchOrganisationalRules(for: currentUserEmail)
    }

    private func fetchOrganisationalRules(for email: String) -> Promise<OrganisationalRules> {
        Promise<OrganisationalRules> { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }

            let clientConfigurationResponse = try awaitPromise(
                self.enterpriseServerApi.getClientConfiguration(for: email)
            )

            let organisationalRules = OrganisationalRules(
                clientConfiguration: clientConfigurationResponse
            )

            self.clientConfigurationProvider.save(clientConfiguration: clientConfigurationResponse)

            resolve(organisationalRules)
        }
        .recover { [weak self] error -> OrganisationalRules in
            guard let self = self else { throw AppErr.nilSelf }
            guard let clientConfig = self.clientConfigurationProvider.fetch() else {
                throw error
            }
            return OrganisationalRules(clientConfiguration: clientConfig)
        }
    }

    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules {
        guard let configuration = self.clientConfigurationProvider.fetch() else {
            fatalError("There should not be a user without OrganisationalRules")
        }

        return OrganisationalRules(clientConfiguration: configuration)
    }
}
