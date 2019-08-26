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

    private let url = "https://flowcrypt.com/attester/"

    private init() { }

    func lookupEmail(email: String) -> Promise<PubkeySearchResult> {
        return Promise<PubkeySearchResult> { [weak self] (resolve, reject) in
            guard let self = self else { reject(CoreError.undefined); return }
            let lookupUrl = self.url + "pub/\(self.normalize(email))"
            let res = try await(URLSession.shared.call(lookupUrl, tolerateStatus: [404]))

            guard res.status == 200 else { reject(CoreError.undefined); return }

            let searchResult = PubkeySearchResult(armored:  String(data: res.data, encoding: .utf8))
            resolve(searchResult)
        }
    }

    private func normalize(_ email: String) -> String {
        return email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
