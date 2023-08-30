//
//  EnterpriseServerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 05.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon

protocol EnterpriseServerApiType {
    var email: String { get }
    var fesUrl: String? { get async throws }

    func getClientConfiguration() async throws -> RawClientConfiguration
    func getReplyToken() async throws -> String
    func upload(message: Data, details: MessageUploadDetails, progressHandler: ((Float) -> Void)?) async throws -> String
}

/// server run by individual enterprise customers, serves client configuration
/// https://flowcrypt.com/docs/technical/enterprise/email-deployment-overview.html
class EnterpriseServerApi: NSObject, EnterpriseServerApiType {

    static let publicEmailProviderDomains = ["gmail.com", "googlemail.com", "outlook.com"]

    private enum Constants {
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

    private var helper: EnterpriseServerApiHelper?

    let email: String
    var fesUrl: String? {
        get async throws {
            if helper == nil {
                self.helper = try await EnterpriseServerApiHelper(email: email)
            }

            return self.helper?.fesUrl
        }
    }

    init(email: String) throws {
        self.email = email

        super.init()
    }

    func getClientConfiguration() async throws -> RawClientConfiguration {
        guard let userDomain = email.emailParts?.domain else {
            throw EnterpriseServerApiError.emailFormat
        }

        do {
            let response: ClientConfigurationResponse = try await performRequest(
                email: email,
                url: "/api/v1/client-configuration?domain=\(userDomain)",
                method: .get,
                withAuthorization: false
            )

            return response.clientConfiguration
        } catch EnterpriseServerApiError.noActiveFesUrl {
            return .empty
        } catch {
            throw error
        }
    }

    func getReplyToken() async throws -> String {
        let response: MessageReplyTokenResponse = try await performRequest(
            email: email,
            url: "/api/v1/message/new-reply-token"
        )

        return response.replyToken
    }

    func upload(message: Data, details: MessageUploadDetails, progressHandler: ((Float) -> Void)?) async throws -> String {
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
            email: email,
            url: "/api/v1/message",
            headers: [contentTypeHeader],
            method: .post,
            body: request.httpBody as Data,
            progressHandler: progressHandler
        )

        return response.url
    }

    private func performRequest<T: Decodable>(
        email: String,
        url: String,
        headers: [URLHeader] = [],
        method: HTTPMethod = .post,
        body: Data? = nil,
        withAuthorization: Bool = true,
        progressHandler: ((Float) -> Void)? = nil
    ) async throws -> T {
        guard let fesUrl = try await fesUrl else {
            throw EnterpriseServerApiError.noActiveFesUrl
        }

        var headers = headers

        if withAuthorization {
            let idToken = try await IdTokenUtils.getIdToken(userEmail: email)
            let authorizationHeader = URLHeader(value: "Bearer \(idToken)", httpHeaderField: "Authorization")
            headers.append(authorizationHeader)
        }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: "\(fesUrl)\(url)",
            method: method,
            body: body,
            headers: headers,
            progressHandler: progressHandler
        )

        let safeResponse = try await ApiCall.shared.call(request)

        guard let data = try? decoder.decode(T.self, from: safeResponse.data)
        else { throw EnterpriseServerApiError.parse }

        return data
    }
}
