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
    private let core: Core
    private let wkd: WKDURLsApiType
    private let attesterApi: AttesterApiType

    init(
        wkd: WKDURLsApiType = WKDURLsApi(),
        attesterApi: AttesterApiType = AttesterApi(),
        core: Core = .shared
    ) {
        self.wkd = wkd
        self.attesterApi = attesterApi
        self.core = core
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
            guard let armoredData = attesterResult.armored,
                  let attesterKeys = try? self.core.parseKeys(armoredOrBinary: armoredData),
                  !attesterKeys.keyDetails.isEmpty else {
                resolve([])
                return
            }
            let attesterPubKeys = attesterKeys.keyDetails
                    .filter { !$0.users.filter { $0.contains(email) }.isEmpty }
            resolve(attesterPubKeys)
        }
    }
}
