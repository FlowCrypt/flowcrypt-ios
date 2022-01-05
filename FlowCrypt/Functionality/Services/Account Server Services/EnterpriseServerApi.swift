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
    func getReplyToken(for email: String) async throws -> String
    func upload(message: Data, details: MessageUploadDetails) async throws -> String
}

/// server run by individual enterprise customers, serves client configuration
/// https://flowcrypt.com/docs/technical/enterprise/email-deployment-overview.html
class EnterpriseServerApi: EnterpriseServerApiType {

    static let publicEmailProviderDomains = ["gmail.com", "googlemail.com", "outlook.com"]

    private enum Constants {
        /// -1001 - request timed out, -1003 - сannot resolve host, -1004 - can't connect to hosts
        /// -1005 - network connection lost, -1006 - dns lookup failed, -1007 - too many redirects
        /// -1008 - resource unavailable
        static let getToleratedNSErrorCodes = [-1001, -1003, -1004, -1005, -1006, -1007, -1008]
        static let getActiveFesTimeout: TimeInterval = 4
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
        guard !Bundle.isDebugBundleWithArgument("--mock-fes-api") else {
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
                tolerateStatus: [404] // 404 tells the app that FES is disabled
            )
            let response = try await ApiCall.call(request)

            if response.status == 404 {
                return nil // FES is explicitly disabled
            }

            guard isExpectedFesServiceResponse(responseData: response.data) else {
                if Bundle.isEnterprise() { // on enterprise build, FES is expected to be running
                    throw AppErr.general("Unpexpected response from FlowCrypt Enterprise Server")
                }
                return nil // on consumer installations, we only use FES if it returns as expected
            }

            return urlBase
        } catch {
            if await shouldTolerateWhenCallingOpportunistically(error) {
                return nil
            } else {
                throw error
            }
        }
    }

    func getClientConfiguration(for email: String) async throws -> RawClientConfiguration {
        guard let userDomain = email.emailParts?.domain else {
            throw EnterpriseServerApiError.emailFormat
        }

        let response: ClientConfigurationResponse = try await performRequest(
            email: email,
            url: "/api/v1/client-configuration?domain=\(userDomain)",
            method: .get,
            withAuthorization: false
        )

        return response.clientConfiguration
    }

    func getReplyToken(for email: String) async throws -> String {
        let response: MessageReplyTokenResponse = try await performRequest(
            email: email,
            url: "/api/v1/message/new-reply-token"
        )

        return response.replyToken
    }

    func upload(message: Data, details: MessageUploadDetails) async throws -> String {
        let detailsData = try details.toJsonData()

        let detailsDataItem = MultipartDataItem(
            data: detailsData,
            name: "details",
            contentType: "application/json"
        )
        let contentDataItem = MultipartDataItem(
            data: message,
            name: "content",
            contentType: "application/octet-stream"
        )

        let request = MultipartDataRequest(items: [detailsDataItem, contentDataItem])

        let contentTypeHeader = URLHeader(
            value: "multipart/form-data; boundary=\(request.boundary)",
            httpHeaderField: "Content-Type"
        )

        let response: MessageUploadResponse = try await performRequest(
            email: details.from,
            url: "/api/v1/message",
            headers: [contentTypeHeader],
            method: .post,
            body: request.httpBody as Data
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

    private func isExpectedFesServiceResponse(responseData: Data) -> Bool {
        // "try?" because unsure what server is running there, want to test without failing
        guard let responseDictionary = try? responseData.toDict() else { return false }
        guard let service = responseDictionary["service"] as? String else { return false }
        return service == "enterprise-server"
    }
    
    private func shouldTolerateWhenCallingOpportunistically(_ error: Error) async -> Bool {
        if Bundle.isEnterprise() {
            return false // FlowCrypt Enterprise Server (FES) required on enterprise bundle
        }
        // on consumer release, FES is called opportunistically - if it's there, it will be used
        // guards first - don't tolerate unknown / other errors. Only interested in network errors.
        guard let apiError = error as? ApiError else { return false }
        guard let nsError = apiError.internalError as NSError? else { return false }
        guard Constants.getToleratedNSErrorCodes.contains(nsError.code) else { return false }
        // when calling FES, we got some sort of network error. Could be FES down or internet down.
        if await doesTheInternetWork() {
            // we got network error from FES, but internet works. We are on consumer release.
            //   we can assume that there is no FES running
            return true // tolerate the error
        } else {
            // we got network error from FES because internet actually doesn't work
            //   throw original error so user can retry
            return false // do not tolertate the error
        }
    }
    
    private func doesTheInternetWork() async -> Bool {
        // this API is mentioned here:
        // https://www.chromium.org/chromium-os/chromiumos-design-docs/network-portal-detection
        let request = ApiCall.Request(
            apiName: "ConnectionTest",
            url: "https://client3.google.com/generate_204",
            timeout: Constants.getActiveFesTimeout
        )
        do {
            let response = try await ApiCall.call(request)
            return response.status == 204
        } catch {
            return false
        }
    }

    private func performRequest<T: Decodable>(
        email: String,
        url: String,
        headers: [URLHeader] = [],
        method: HTTPMethod = .post,
        body: Data? = nil,
        withAuthorization: Bool = true
    ) async throws -> T {
        guard let fesUrl = try await getActiveFesUrl(for: email) else {
            throw EnterpriseServerApiError.noActiveFesUrl
        }

        if withAuthorization {
            let idToken = try await getIdToken(email: email)
            let authorizationHeader = URLHeader(value: "Bearer \(idToken)", httpHeaderField: "Authorization")
            var headers = headers
            headers.append(authorizationHeader)
        }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: "\(fesUrl)\(url)",
            method: method,
            body: body,
            headers: headers
        )

        let safeResponse = try await ApiCall.call(request)

        guard let data = try? decoder.decode(T.self, from: safeResponse.data)
        else { throw EnterpriseServerApiError.parse }

        return data
    }
}
