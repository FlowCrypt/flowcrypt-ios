//
//  OrganisationalRulesService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol OrganisationalRulesServiceType {
    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules?>
    func fetchOrganisationalRules(for email: String) -> Promise<OrganisationalRules?>

    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules?
}

final class OrganisationalRulesService {

    private let enterpriseServerApi: EnterpriseServerApiType
    private let clientConfigurationProvider: ClientConfigurationProviderType

    init(
        storage: @escaping @autoclosure CacheStorage = DataService.shared.storage,
        enterpriseServerApi: EnterpriseServerApiType = EnterpriseServerApi()
    ) {
        self.enterpriseServerApi = enterpriseServerApi
        self.clientConfigurationProvider = ClientConfigurationProvider(storage: storage())
    }
}

// MARK: - OrganisationalRulesServiceType
extension OrganisationalRulesService: OrganisationalRulesServiceType {

    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules?> {
        guard let currentUser = DataService.shared.currentUser else {
            return Promise<OrganisationalRules?> { _, reject in
                reject(OrganisationalRulesServiceError.noCurrentUser)
            }
        }
        return fetchOrganisationalRules(for: currentUser.email)
    }

    func fetchOrganisationalRules(for email: String) -> Promise<OrganisationalRules?> {
        Promise<OrganisationalRules?> { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }

            guard let clientConfigurationResponse = try awaitPromise(
                    self.enterpriseServerApi.getClientConfiguration(for: email)
            ) else {
                resolve(nil)
                return
            }
            guard let organisationalRules = OrganisationalRules(
                    clientConfiguration: clientConfigurationResponse,
                    email: email
            ) else {
                resolve(nil)
                return
            }

            self.clientConfigurationProvider.save(clientConfiguration: clientConfigurationResponse)

            resolve(organisationalRules)
        }
    }

    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules? {
        guard let currentUser = DataService.shared.currentUser,
              let configuration = self.clientConfigurationProvider.fetch()
        else {
            return nil
        }

        return OrganisationalRules(
            clientConfiguration: configuration,
            email: currentUser.email
        )
    }
}
