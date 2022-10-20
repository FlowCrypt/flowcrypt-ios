//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon

protocol AttesterApiType {
    func lookup(email: String) async throws -> [KeyDetails]
    func submitPrimaryEmailPubkey(email: String, pubkey: String, idToken: String) async throws -> String
    func submitPubkeyWithConditionalEmailVerification(email: String, pubkey: String) async throws -> String
    func testWelcome(email: String, pubkey: String, idToken: String) async throws
}

/// Public key server run by us that is shared across customers
/// Some enterprise customers may have this functionality disabled
final class AttesterApi: AttesterApiType {

    private enum Constants {
        static let lookupEmailRequestTimeout: TimeInterval = 10
        static let apiName = "AttesterApi"
    }

    private let core: Core
    private let clientConfiguration: ClientConfiguration

    init(
        core: Core = .shared,
        clientConfiguration: ClientConfiguration
    ) {
        self.core = core
        self.clientConfiguration = clientConfiguration
    }

    private func constructUrlBase() -> String {
        guard !Bundle.shouldUseMockAttesterApi else {
            return "\(GeneralConstants.Mock.backendUrl)/attester" // mock
        }
        return "https://flowcrypt.com/attester" // live
    }

    private func pubUrl(email: String) -> String {
        let normalizedEmail = email
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return constructUrlBase() + "/pub/" + normalizedEmail
    }
}

extension AttesterApi {
    func lookup(email: String) async throws -> [KeyDetails] {
        guard try clientConfiguration.canLookupThisRecipientOnAttester(recipient: email) else {
            return []
        }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: pubUrl(email: email),
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
    func submitPrimaryEmailPubkey(email: String, pubkey: String, idToken: String) async throws -> String {
        return try await submit(pubkey: pubkey, for: email, idToken: idToken)
    }

    @discardableResult
    func submitPubkeyWithConditionalEmailVerification(email: String, pubkey: String) async throws -> String {
        return try await submit(pubkey: pubkey, for: email)
    }

    private func submit(pubkey: String, for email: String, idToken: String? = nil) async throws -> String {
        let authHeader = idToken
            .flatMap { URLHeader(value: "Bearer \($0)", httpHeaderField: "Authorization") }

        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: pubUrl(email: email),
            method: .post,
            body: pubkey.data(),
            headers: [authHeader].compactMap { $0 }
        )
        let res = try await ApiCall.call(request)
        return res.data.toStr()
    }

    func testWelcome(email: String, pubkey: String, idToken: String) async throws {
        let request = ApiCall.Request(
            apiName: Constants.apiName,
            url: constructUrlBase() + "/welcome-message",
            method: .post,
            body: try? JSONSerialization.data(withJSONObject: ["email": email, "pubkey": pubkey]),
            headers: [
                URLHeader(value: "application/json", httpHeaderField: "Content-Type"),
                URLHeader(value: "Bearer \(idToken)", httpHeaderField: "Authorization")
            ]
        )
        _ = try await ApiCall.call(request) // will throw on non-200
    }
}
