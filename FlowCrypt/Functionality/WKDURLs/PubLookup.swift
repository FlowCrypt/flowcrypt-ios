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
            // TODO: - we are blindly choosing .first public key, in the future we should return [Contact]
            // then eg encrypt for all returned Contacts
            // also stop throwing below - no point. Return
            //  empty array then handle downstream
            guard let keyDetail = keyDetails.first else {
                throw ContactsError.keyMissing
            }
            resolve(Contact(email: email, keyDetail: keyDetail))
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

}
