//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol AttesterApiType {
    func lookup(email: String) async throws -> [KeyDetails]
    func update(email: String, pubkey: String, token: String?) async throws -> String
    func replace(email: String, pubkey: String) async throws -> String
    func testWelcome(email: String, pubkey: String) async throws
}

/// Public key server run by us that is shared across customers
/// Some enterprise customers may have this functionality disabled
final class AttesterApi: AttesterApiType {

    private enum Constants {
        static let lookupEmailRequestTimeout: TimeInterval = 10
        static let baseURL = "https://flowcrypt.com/attester/"
        static let apiName = "AttesterApi"
    }

    private let core: Core
    private let clientConfiguration: ClientConfiguration

    init(
        core: Core = .shared,
        clientConfigurationService: ClientConfigurationServiceType = ClientConfigurationService()
    ) {
        self.core = core
        self.clientConfiguration = clientConfigurationService.getSavedForCurrentUser()
    }

    private func urlPub(emailOrLongid: String) -> String {
        let normalizedEmail = emailOrLongid
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(Constants.baseURL)pub/\(normalizedEmail)"
    }
}

extension AttesterApi {
    func lookup(email: String) async throws -> [KeyDetails] {
        if !(try clientConfiguration.canLookupThisRecipientOnAttester(recipient: email)) {
            return []
        }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: urlPub(emailOrLongid: email),
            timeout: Constants.lookupEmailRequestTimeout,
            tolerateStatus: [404]
        )
        let res = try await ApiCall.call(request)

        if res.status >= 200, res.status <= 299 {
            return try await core.parseKeys(armoredOrBinary: res.data).keyDetails
        }

        if res.status == 404 {
            return []
        }

        throw AppErr.unexpected(
            "programing error - should have been caught above" +
            " - unexpected status \(res.status) when looking up pubkey for \(email)"
        )
    }

    @discardableResult
    func update(email: String, pubkey: String, token: String?) async throws -> String {
        let httpMethod: HTTPMetod
        let headers: [URLHeader]

        if let value = token {
            httpMethod = .post
            headers = [URLHeader(value: "Bearer \(value)", httpHeaderField: "Authorization")]
        } else {
            httpMethod = .put
            headers = []
        }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: urlPub(emailOrLongid: email),
            method: httpMethod,
            body: pubkey.data(),
            headers: headers
        )
        let res = try await ApiCall.call(request)
        return res.data.toStr()
    }

    @discardableResult
    func replace(email: String, pubkey: String) async throws -> String {
        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: urlPub(emailOrLongid: email),
            method: .post,
            body: pubkey.data()
        )
        let res = try await ApiCall.call(request)
        return res.data.toStr()
    }

    func testWelcome(email: String, pubkey: String) async throws {
        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: Constants.baseURL + "test/welcome",
            method: .post,
            body: try? JSONSerialization.data(withJSONObject: ["email": email, "pubkey": pubkey]),
            headers: [URLHeader(value: "application/json", httpHeaderField: "Content-Type")]
        )
        _ = try await ApiCall.call(request) // will throw on non-200
    }
}
