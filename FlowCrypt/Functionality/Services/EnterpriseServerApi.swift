//
//  EnterpriseServerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 05.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises

protocol EnterpriseServerApiType {
    func getActiveFesUrl(for email: String) -> Promise<String?>
    func getActiveFesUrlForCurrentUser() -> Promise<String?>

    func getDomainRules(for email: String) -> Promise<DomainRules?>
    func getDomainRulesForCurrentUser() -> Promise<DomainRules?>
}

class EnterpriseServerApi: EnterpriseServerApiType {

    private enum Constants {
        static let getActiveFesTimeout: TimeInterval = 4

        static let serviceKey = "service"
        static let serviceNeededValue = "enterprise-server"
    }

    private struct ClientConfiguration: Codable {
        let domainRules: DomainRules

        private enum CodingKeys: String, CodingKey {
            case domainRules = "clientConfiguration"
        }
    }

    func getActiveFesUrlForCurrentUser() -> Promise<String?> {
        guard let email = DataService.shared.currentUser?.email else {
            return Promise<String?> { resolve, _ in
                resolve(nil)
            }
        }
        return getActiveFesUrl(for: email)
    }

    func getActiveFesUrl(for email: String) -> Promise<String?> {
        Promise<String?> { resolve, _ in
            guard let userDomain = email.recipientDomain,
                  !Configuration.publicEmailProviderDomains.contains(userDomain) else {
                resolve(nil)
                return
            }
            let urlString = "https://fes.\(userDomain)/"
            let request = URLRequest.urlRequest(
                with: "\(urlString)api/",
                method: .get,
                body: nil
            )

            let response = try? awaitPromise(URLSession.shared.call(request))
            guard let safeReponse = response,
                  let responseDictionary = try? safeReponse.data.toDict(),
                  let service = responseDictionary[Constants.serviceKey] as? String,
                  service == Constants.serviceNeededValue else {
                resolve(nil)
                return
            }

            resolve(urlString)
        }
        .timeout(Constants.getActiveFesTimeout)
        .recoverFromTimeOut(result: nil)
    }

    func getDomainRules(for email: String) -> Promise<DomainRules?> {
        Promise<DomainRules?> { resolve, _ in
            guard let userDomain = email.recipientDomain,
                  !Configuration.publicEmailProviderDomains.contains(userDomain) else {
                resolve(nil)
                return
            }
            let request = URLRequest.urlRequest(
                with: "https://fes.\(userDomain)/api/v1/client-configuration?domain=\(userDomain)",
                method: .get,
                body: nil
            )
            let response = try? awaitPromise(URLSession.shared.call(request))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            guard let safeReponse = response,
                  let domainRules = (try? decoder.decode(ClientConfiguration.self, from: safeReponse.data))?.domainRules else {
                resolve(nil)
                return
            }
            resolve(domainRules)
        }
    }

    func getDomainRulesForCurrentUser() -> Promise<DomainRules?> {
        guard let email = DataService.shared.currentUser?.email else {
            return Promise<DomainRules?> { resolve, _ in
                resolve(nil)
            }
        }
        return getDomainRules(for: email)
    }
}
