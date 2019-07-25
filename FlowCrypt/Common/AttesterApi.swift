//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct PubkeySearchResult {
    let armored: String?
}

class AttesterApi {

    private static let url = "https://flowcrypt.com/attester/"

    static func lookupEmail(email: String) -> Promise<PubkeySearchResult> {
        return Promise<PubkeySearchResult>.valueReturning {
            let lookupUrl = AttesterApi.url + "pub/\(AttesterApi.normalize(email))"
            let res = try await(URLSession.shared.call(lookupUrl, tolerateStatus: [404]))
            return PubkeySearchResult(armored: res.status == 200 ? String(data: res.data, encoding: .utf8) : nil)
        }
    }

    private static func normalize(_ email: String) -> String {
        return email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
