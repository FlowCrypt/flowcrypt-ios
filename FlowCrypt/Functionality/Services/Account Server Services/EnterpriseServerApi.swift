//
//  EnterpriseServerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 05.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore
import FlowCryptCommon

protocol EnterpriseServerApiType {
    func getActiveFesUrl(for email: String) async throws -> String?
    func getClientConfiguration(for email: String) async throws -> RawClientConfiguration
    func upload(message: Data, sender: String, to: [String], cc: [String], bcc: [String]) async throws -> String
}

/// server run by individual enterprise customers, serves client configuration
/// https://flowcrypt.com/docs/technical/enterprise/email-deployment-overview.html
class EnterpriseServerApi: EnterpriseServerApiType {

    static let publicEmailProviderDomains = ["gmail.com", "googlemail.com", "outlook.com"]

    private enum Constants {
        /// 404 - Not Found
        static let getToleratedHTTPStatuses = [404]
        /// -1001 - request timed out, -1003 - сannot resolve host, -1004 - can't connect to hosts,
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

    private struct MessageReplyTokenResponse: Decodable {
        let replyToken: String
    }

    private struct MessageUploadResponse: Decodable {
        let url: String
    }

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private func constructUrlBase(emailDomain: String) -> String {
        guard !CommandLine.isDebugBundleWithArgument("--mock-fes-api") else {
            return "http://127.0.0.1:8001/fes" // mock
        }
        return "https://fes.\(emailDomain)" // live
    }

    func getActiveFesUrl(for email: String) async throws -> String? {
        do {
            guard let userDomain = email.emailParts?.domain,
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
        guard let userDomain = email.emailParts?.domain else {
            throw EnterpriseServerApiError.emailFormat
        }

        let response: ClientConfigurationResponse = try await performRequest(
            email: email,
            url: "/api/v1/client-configuration?domain=\(userDomain)",
            method: .get
        )

        return response.clientConfiguration
    }

    func upload(message: Data,
                sender: String,
                to: [String],
                cc: [String],
                bcc: [String]
    ) async throws -> String {
        let replyToken = try await getReplyToken(for: sender)

        let uploadRequest = MessageUploadDetails(
            associateReplyToken: replyToken,
            from: sender,
            to: to,
            cc: cc,
            bcc: bcc
        )

        let boundary = UUID().uuidString

        let body = MessageUploadRequest(
            boundary: boundary,
            details: uploadRequest.jsonString,
            content: message
        ).httpBody

        let contentTypeHeader = URLHeader(
            value: "multipart/form-data; boundary=\(boundary)",
            httpHeaderField: "Content-Type"
        )

        let response: MessageUploadResponse = try await performRequest(
            email: sender,
            url: "/api/v1/message",
            headers: [contentTypeHeader],
            method: .post,
            body: body as Data
        )

        return response.url
    }

    // MARK: - Helpers
    private func getIdToken(email: String) async throws -> String {
        let googleService = GoogleUserService(
            currentUserEmail: email,
            appDelegateGoogleSessionContainer: nil
        )

        return try await googleService.getCachedOrRefreshedIdToken()
    }

    private func getReplyToken(for email: String) async throws -> String {
        let response: MessageReplyTokenResponse = try await performRequest(
            email: email,
            url: "/api/v1/message/new-reply-token"
        )

        return response.replyToken
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

    private func performRequest<T: Decodable>(
        email: String,
        url: String,
        headers: [URLHeader] = [],
        method: HTTPMethod = .post,
        body: Data? = nil
    ) async throws -> T {
        guard let fesUrl = try await getActiveFesUrl(for: email) else {
            throw EnterpriseServerApiError.noActiveFesUrl
        }

        let idToken = try await getIdToken(email: email)
        let authorizationHeader = URLHeader(value: "Bearer \(idToken)", httpHeaderField: "Authorization")

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: "\(fesUrl)\(url)",
            method: method,
            body: body,
            headers: [authorizationHeader] + headers
        )

        let safeResponse = try await ApiCall.call(request)

        guard let data = try? decoder.decode(T.self, from: safeResponse.data)
        else { throw EnterpriseServerApiError.parse }

        return data
    }
}
