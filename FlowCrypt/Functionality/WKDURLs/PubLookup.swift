//
//  PubLookup.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 31.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
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

        // TODO: - we are blindly choosing .first public key, in the future we should return [Contact]
        // and have some intelligent code in the consumers to choose the right public key
        // for whatever purpose it's used for.
        guard let keyDetail = keyDetails.first else {
            return Promise(ContactsError.keyMissing)
        }

        let keyIds = keyDetails.flatMap(\.ids)
        let longids = keyIds.map(\.longid)
        let fingerprints = keyIds.map(\.fingerprint)

        let contact = Contact(
            email: email,
            name: keyDetail.users.first ?? email,
            pubKey: keyDetail.public,
            pubKeyLastSig: nil, // TODO: - will be provided later
            pubkeyLastChecked: Date(),
            pubkeyExpiresOn: nil, // TODO: - will be provided later
            longids: longids,
            lastUsed: nil,
            fingerprints: fingerprints,
            pubkeyCreated: Date(timeIntervalSince1970: Double(keyDetail.created)),
            algo: keyDetail.algo
        )
        return Promise(contact)
    }
}
