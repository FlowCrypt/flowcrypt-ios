//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct PubkeySearchResult {
    let armored: String?
}

final class AttesterApi {

    static let shared: AttesterApi = AttesterApi()

    private static let url = "https://flowcrypt.com/attester/"

    private init() { }

    func lookupEmail(email: String) -> Promise<PubkeySearchResult> {
        return Promise { () -> PubkeySearchResult in
            let lookupUrl = AttesterApi.url + "pub/\(AttesterApi.normalize(email))"
            let res = try await(URLSession.shared.call(lookupUrl, tolerateStatus: [404]))
            if res.status >= 200 && res.status <= 299 {
                return PubkeySearchResult(armored: String(data: res.data, encoding: .utf8))
            }
            if res.status == 404 {
                return PubkeySearchResult(armored: nil)
            }
            throw FCError.message("Status \(res.status) when looking up pubkey for \(email)")
        }
    }

    private static func normalize(_ email: String) -> String {
        return email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
