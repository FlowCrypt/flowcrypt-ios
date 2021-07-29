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

    func getClientConfiguration(for email: String) -> Promise<ClientConfiguration>
    func getClientConfigurationForCurrentUser() -> Promise<ClientConfiguration>
}

enum EnterpriseServerApiError: Error {
    case parse
    case emailFormat
}
extension EnterpriseServerApiError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .parse: return "organisational_rules_parse_error_description".localized
        case .emailFormat: return "organisational_rules_email_format_error_description".localized
        }
    }
}

class EnterpriseServerApi: EnterpriseServerApiType {

    private enum Constants {
        static let getActiveFesTimeout: TimeInterval = 4

        static let serviceKey = "service"
        static let serviceNeededValue = "enterprise-server"
    }

    private struct ClientConfigurationContainer: Codable {
        let clientConfiguration: ClientConfiguration

        private enum CodingKeys: String, CodingKey {
            case clientConfiguration
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

    func getClientConfiguration(for email: String) -> Promise<ClientConfiguration> {
        Promise<ClientConfiguration> { resolve, reject in
            guard let userDomain = email.recipientDomain else {
                reject(EnterpriseServerApiError.emailFormat)
                return
            }
            if Configuration.publicEmailProviderDomains.contains(userDomain) {
                resolve(.empty)
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
                  let clientConfiguration = (try? decoder.decode(
                    ClientConfigurationContainer.self,
                    from: safeReponse.data
                  ))?.clientConfiguration
            else {
                reject(EnterpriseServerApiError.parse)
                return
            }
            resolve(clientConfiguration)
        }
    }

    func getClientConfigurationForCurrentUser() -> Promise<ClientConfiguration> {
        guard let email = DataService.shared.currentUser?.email else {
            return Promise<ClientConfiguration> { _, _ in
                fatalError("User has to be set while getting client configuration")
            }
        }
        return getClientConfiguration(for: email)
    }
}
