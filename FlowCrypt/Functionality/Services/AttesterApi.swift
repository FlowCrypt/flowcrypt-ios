//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct PubkeySearchResult {
    let email: String
    let armored: String?
}

protocol AttesterApiType {
    func lookupEmail(email: String) -> Promise<PubkeySearchResult>
    func updateKey(email: String, pubkey: String) -> Promise<String>
    func replaceKey(email: String, pubkey: String) -> Promise<String>
    func testWelcome(email: String, pubkey: String) -> Promise<Void>
}

final class AttesterApi: AttesterApiType {
    static let shared: AttesterApi = AttesterApi()
    private static var url = "https://flowcrypt.com/attester/"

    private init() {}

    func lookupEmail(email: String) -> Promise<PubkeySearchResult> {
        Promise { () -> PubkeySearchResult in
            let request = AttesterApi.urlPub(emailOrLongid: email)
            let res = try await(URLSession.shared.call(request, tolerateStatus: [404]))

            if res.status >= 200, res.status <= 299 {
                return PubkeySearchResult(email: email, armored: res.data.toStr())
            }
            if res.status == 404 {
                return PubkeySearchResult(email: email, armored: nil)
            }
            // programming error because should never happen
            throw AppErr.unexpected("Status \(res.status) when looking up pubkey for \(email)")
        }
    }

    @discardableResult
    func updateKey(email: String, pubkey: String) -> Promise<String> {
        Promise { () -> String in
            var req = URLRequest(url: URL(string: AttesterApi.urlPub(emailOrLongid: email))!)
            req.httpMethod = "PUT"
            req.httpBody = pubkey.data()
            let res = try await(URLSession.shared.call(req)) // will throw on non-200
            return res.data.toStr()
        }
    }

    @discardableResult
    func replaceKey(email: String, pubkey: String) -> Promise<String> {
        Promise { () -> String in
            var req = URLRequest(url: URL(string: AttesterApi.urlPub(emailOrLongid: email))!)
            req.httpMethod = "POST"
            req.httpBody = pubkey.data()
            let res = try await(URLSession.shared.call(req)) // will throw on non-200
            return res.data.toStr()
        }
    }

    @discardableResult
    func testWelcome(email: String, pubkey: String) -> Promise<Void> {
        return Promise { () -> Void in
            var req = URLRequest(url: URL(string: AttesterApi.url + "test/welcome")!)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "pubkey": pubkey])
            _ = try await(URLSession.shared.call(req)) // will throw on non-200
        }
    }

    private static func urlPub(emailOrLongid: String) -> String {
        "\(AttesterApi.url)pub/\(AttesterApi.normalize(emailOrLongid))"
    }

    private static func normalize(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
