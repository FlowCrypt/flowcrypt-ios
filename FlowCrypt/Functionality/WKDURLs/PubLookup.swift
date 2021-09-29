//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

protocol PubLookupType {
    func lookup(with email: String) -> Promise<Contact>
}

class PubLookup: PubLookupType {
    private let wkd: WKDURLsApiType
    private let attesterApi: AttesterApiType

    init(
        wkd: WKDURLsApiType = WKDURLsApi(),
        attesterApi: AttesterApiType = AttesterApi()
    ) {
        self.wkd = wkd
        self.attesterApi = attesterApi
    }

    func lookup(with email: String) -> Promise<Contact> {
        Promise<Contact> { resolve, _ in
            let keyDetails = try awaitPromise(self.getKeyDetails(email))
            let contact = try awaitPromise(self.parseKey(keyDetails: keyDetails, for: email))
            resolve(contact)
        }
    }

    private func getKeyDetails(_ email: String) -> Promise<[KeyDetails]> {

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

    private func parseKey(keyDetails: [KeyDetails], for email: String) -> Promise<Contact> {

        do {
            let contact = try Contact(email: email, keyDetails: keyDetails)
            return Promise(contact)
        } catch {
            return Promise(error)
        }
    }
}
