//
//  EnterpriseServerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 05.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

protocol EnterpriseServerApiType {
    func getActiveFesUrl(for email: String) async throws -> String?
    func getClientConfiguration(for email: String) async throws -> RawClientConfiguration
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

/// server run by individual enterprise customers, serves client configuration
/// https://flowcrypt.com/docs/technical/enterprise/email-deployment-overview.html
class EnterpriseServerApi: EnterpriseServerApiType {

    static let publicEmailProviderDomains = ["gmail.com", "googlemail.com", "outlook.com"]

    private enum Constants {
        /// 404 - Not Found
        static let getToleratedHTTPStatuses = [404]
        /// -1001 - request timed out, -1003 - сannot resolve host, -1004 - can't conenct to hosts,
        /// -1005 - network connection lost, -1006 - dns lookup failed, -1007 - too many redirects
        /// -1008 - resource unavailable
        static let getToleratedNSErrorCodes = [-1001, -1003, -1004, -1005, -1006, -1007, -1008]
        static let getActiveFesTimeout: TimeInterval = 4

        static let serviceKey = "service"
        static let serviceNeededValue = "enterprise-server"

        static let apiName = "EnterpriseServerApi"
    }

    private struct ClientConfigurationResponse: Codable {
        let clientConfiguration: RawClientConfiguration
    }

    private func constructUrlBase(emailDomain: String) -> String {
        guard !CommandLine.isDebugBundleWithArgument("--mock-fes-api") else {
            return "http://127.0.0.1:8001/fes" // mock
        }
        return "https://fes.\(emailDomain)" // live
    }

    func getActiveFesUrl(for email: String) async throws -> String? {
        do {
            guard let userDomain = email.emailDomain,
                  !EnterpriseServerApi.publicEmailProviderDomains.contains(userDomain) else {
                return nil
            }
            let urlBase = constructUrlBase(emailDomain: userDomain)
            let request = ApiCall.Request(
                apiName: Constants.apiName,
                url: "\(urlBase)/api/",
                timeout: Constants.getActiveFesTimeout,
                tolerateStatus: Constants.getToleratedHTTPStatuses
            )
            let response = try await ApiCall.call(request)

            if Constants.getToleratedHTTPStatuses.contains(response.status) {
                return nil
            }

            guard let responseDictionary = try? response.data.toDict(),
                  let service = responseDictionary[Constants.serviceKey] as? String,
                  service == Constants.serviceNeededValue else {
                return nil
            }

            return urlBase
        } catch {
            guard shouldTolerateWhenCallingOpportunistically(error) else {
                throw error
            }
            return nil
        }
    }

    func getClientConfiguration(for email: String) async throws -> RawClientConfiguration {
        guard let userDomain = email.emailDomain else {
            throw EnterpriseServerApiError.emailFormat
        }

        guard let fesUrl = try await getActiveFesUrl(for: email) else {
            return .empty
        }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: "\(fesUrl)/api/v1/client-configuration?domain=\(userDomain)"
        )
        let safeReponse = try await ApiCall.call(request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let clientConfiguration = (try? decoder.decode(
                ClientConfigurationResponse.self,
                from: safeReponse.data
              ))?.clientConfiguration
        else {
            throw EnterpriseServerApiError.parse
        }
        return clientConfiguration
    }

    private func shouldTolerateWhenCallingOpportunistically(_ error: Error) -> Bool {
        guard
            let apiError = error as? ApiError,
            let nsError = apiError.internalError as NSError?,
            Constants.getToleratedNSErrorCodes.contains(nsError.code)
        else {
            return false
        }
        return true
    }
}
