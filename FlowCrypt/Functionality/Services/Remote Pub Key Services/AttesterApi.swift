//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct PubkeySearchResult {
    let email: String
    let armored: Data?
}

protocol AttesterApiType {
    func lookupEmail(email: String) async throws -> [KeyDetails]
    func updateKey(email: String, pubkey: String, token: String?) -> Promise<String>
    func replaceKey(email: String, pubkey: String) -> Promise<String>
    func testWelcome(email: String, pubkey: String) -> Promise<Void>
}

/// Public key server run by us that is shared across customers
/// Some enterprise customers may have this functionality disabled
final class AttesterApi: AttesterApiType {

    private enum Constants {
        static let lookupEmailRequestTimeout: TimeInterval = 10
    }

    private enum Endpoint {
        static let baseURL = "https://flowcrypt.com/attester/"
    }

    private let core: Core
    private let clientConfiguration: ClientConfiguration

    init(
        core: Core = .shared,
        clientConfigurationService: ClientConfigurationServiceType = ClientConfigurationService()
    ) {
        self.core = core
        self.clientConfiguration = clientConfigurationService.getSavedClientConfigurationForCurrentUser()
    }

    private func urlPub(emailOrLongid: String) -> String {
        let normalizedEmail = emailOrLongid
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(Endpoint.baseURL)pub/\(normalizedEmail)"
    }
}

extension AttesterApi {
    func lookupEmail(email: String) async throws -> [KeyDetails] {
        if !(try clientConfiguration.canLookupThisRecipientOnAttester(recipient: email)) {
            return []
        }

        let res = try await URLSession.shared.asyncCall(urlPub(emailOrLongid: email), tolerateStatus: [404])

        if res.status >= 200, res.status <= 299 {
            let keys = try core.parseKeys(armoredOrBinary: res.data)
            let pubKeys = keys.keyDetails
                    .filter { !$0.users.filter { $0.contains(email) }.isEmpty }
            return pubKeys
        }

        if res.status == 404 {
            return []
        }

        // programming error because should never happen
        throw AppErr.unexpected("Status \(res.status) when looking up pubkey for \(email)")
    }

    @discardableResult
    func updateKey(email: String, pubkey: String, token: String?) -> Promise<String> {
        let httpMethod: HTTPMetod
        let headers: [URLHeader]

        if let value = token {
            httpMethod = .post
            headers = [URLHeader(value: "Bearer \(value)", httpHeaderField: "Authorization")]
        } else {
            httpMethod = .put
            headers = []
        }

        let request = URLRequest.urlRequest(
            with: urlPub(emailOrLongid: email),
            method: httpMethod,
            body: pubkey.data(),
            headers: headers
        )
        return Promise { () -> String in
            let res = try awaitPromise(URLSession.shared.call(request))
            return res.data.toStr()
        }
    }

    @discardableResult
    func replaceKey(email: String, pubkey: String) -> Promise<String> {
        let request = URLRequest.urlRequest(
            with: urlPub(emailOrLongid: email),
            method: .post,
            body: pubkey.data()
        )
        return Promise { () -> String in
            let res = try awaitPromise(URLSession.shared.call(request))
            return res.data.toStr()
        }
    }

    @discardableResult
    func testWelcome(email: String, pubkey: String) -> Promise<Void> {
        let request = URLRequest.urlRequest(
            with: Endpoint.baseURL + "test/welcome",
            method: .post,
            body: try? JSONSerialization.data(withJSONObject: ["email": email, "pubkey": pubkey]),
            headers: [URLHeader(value: "application/json", httpHeaderField: "Content-Type")]
        )
        return Promise { () -> Void in
            _ = try awaitPromise(URLSession.shared.call(request)) // will throw on non-200
        }
    }
}
