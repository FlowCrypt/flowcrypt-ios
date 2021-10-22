//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

protocol PubLookupType {
    func lookup(with email: String) async throws -> RecipientWithPubKeys
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

    func lookup(with email: String) async throws -> RecipientWithPubKeys {
        let wkdResult = try await wkd.lookupEmail(email)
        if !wkdResult.isEmpty {
            return RecipientWithPubKeys(email: email, keyDetails: wkdResult)
        }

        let attesterResult = try await attesterApi.lookupEmail(email: email)
        return RecipientWithPubKeys(email: email, keyDetails: attesterResult)
    }
}
