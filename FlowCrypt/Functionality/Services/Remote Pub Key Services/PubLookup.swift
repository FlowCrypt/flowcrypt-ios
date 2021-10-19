//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

protocol PubLookupType {
    func lookup(with email: String) -> Promise<RecipientWithPubKeys>
}

class PubLookup: PubLookupType {
    private let wkd: WkdApiType
    private let attesterApi: AttesterApiType

    init(
        wkd: WkdApiType = WkdApi(),
        attesterApi: AttesterApiType = AttesterApi()
    ) {
        self.wkd = wkd
        self.attesterApi = attesterApi
    }

    func lookup(with email: String) -> Promise<RecipientWithPubKeys> {
        Promise<RecipientWithPubKeys> { [weak self] resolve, _ in
            guard let self = self else {
                resolve(RecipientWithPubKeys(email: email, keyDetails: []))
                return
            }

            let wkdResult = try awaitPromise(self.wkd.lookupEmail(email))
            if !wkdResult.isEmpty {
                resolve(RecipientWithPubKeys(email: email, keyDetails: wkdResult))
                return
            }

            let attesterResult = try awaitPromise(self.attesterApi.lookupEmail(email: email))
            resolve(RecipientWithPubKeys(email: email, keyDetails: attesterResult))
            return
        }
    }
}
