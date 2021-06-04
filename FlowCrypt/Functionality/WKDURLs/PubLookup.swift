//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises

protocol PubLookupType {
    func lookupEmail(_ email: String) -> Promise<[String]>
}

class PubLookup {
    private let wkd: WKDURLsApiType
    private let attesterApi: AttesterApiType

    init(
        wkd: WKDURLsApiType = WKDURLsApi(),
        attesterApi: AttesterApiType = AttesterApi()
    ) {
        self.wkd = wkd
        self.attesterApi = attesterApi
    }

    func lookupEmail(_ email: String) -> Promise<[KeyDetails]> {

        Promise<[KeyDetails]> { [weak self] resolve, _ in
            guard let self = self else {
                resolve([])
                return
            }

            let wkdResult = try awaitPromise(self.wkd.lookupEmail(email))
            if !wkdResult.isEmpty {
                resolve(wkdResult)
            }

            let attesterResult = try awaitPromise(self.attesterApi.lookupEmail(email: email))
            resolve(attesterResult)
        }
    }
}
