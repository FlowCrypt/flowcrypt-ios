//
//  OrganisationalRulesService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import Foundation
import Promises

protocol OrganisationalRulesServiceType {
    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules>
    func fetchOrganisationalRules(for email: String) -> Promise<OrganisationalRules>

    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules

    func getEmailKeyManagerPrivateKeys() -> Promise<Void>
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

    func fetchOrganisationalRulesForCurrentUser() -> Promise<OrganisationalRules> {
        guard let currentUser = DataService.shared.currentUser else {
            return Promise<OrganisationalRules> { _, reject in
                reject(OrganisationalRulesServiceError.noCurrentUser)
            }
        }
        return fetchOrganisationalRules(for: currentUser.email)
    }

    func fetchOrganisationalRules(for email: String) -> Promise<OrganisationalRules> {
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

    func getEmailKeyManagerPrivateKeys() -> Promise<Void> {
        Promise<Void> { [weak self] resolve, _ in
            guard let self = self else { return }
            let organisationalRules = self.getSavedOrganisationalRulesForCurrentUser()
            guard let keyManagerUrlString = organisationalRules.keyManagerUrlString else {
                resolve(())
                return
            }
            let urlString = "\(keyManagerUrlString.addTrailingSlashIfNeeded)v1/keys/private"
            let headers = [
                URLHeader(
                    value: "Bearer \(DataService.shared.token ?? "")",
                    httpHeaderField: "Authorization"
                )]
            let request = URLRequest.urlRequest(
                with: urlString,
                method: .get,
                body: nil,
                headers: headers
            )

            let _ = try? awaitPromise(URLSession.shared.call(request))
            resolve(())
        }
    }

    func getSavedOrganisationalRulesForCurrentUser() -> OrganisationalRules {
        guard let configuration = self.clientConfigurationProvider.fetch() else {
            assertionFailure("There should not be a user without OrganisationalRules")
            return OrganisationalRules(clientConfiguration: .empty)
        }

        return OrganisationalRules(clientConfiguration: configuration)
    }
}
