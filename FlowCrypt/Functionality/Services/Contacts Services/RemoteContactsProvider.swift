//
//  RemoteContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol ContactsProviderType {
    func searchContact(with email: String) -> Promise<Contact>
}

struct RemoteContactsProvider {
    let api: AttesterApiType

    init(
        api: AttesterApiType = AttesterApi()
    ) {
        self.api = api
    }
}

extension RemoteContactsProvider: ContactsProviderType {
    func searchContact(with email: String) -> Promise<Contact> {
        Promise<Contact> { resolve, _ in
            let keyDetails = try awaitPromise(self.api.lookupEmail(email: email))
            let contact = try awaitPromise(self.parseKey(keyDetails: keyDetails, for: email))
            resolve(contact)
        }
    }

    private func parseKey(keyDetails: [KeyDetails], for email: String) -> Promise<Contact> {

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
