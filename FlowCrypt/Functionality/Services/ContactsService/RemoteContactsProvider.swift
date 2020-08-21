//
//  RemoteContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

struct RemoteContactsProvider {
    let api: AttesterApiType
    let core: Core

    init(
        api: AttesterApiType = AttesterApi(),
        core: Core = .shared
    ) {
        self.api = api
        self.core = core
    }
}

extension RemoteContactsProvider: ContactsServiceType {
    func searchContact(with email: String) -> Promise<Contact> {
        Promise<Contact> { resolve, _ in
            let armoredData = try await(self.api.lookupEmail(email: email)).armored
            let contact = try await(self.parseKey(data: armoredData, for: email))
            resolve(contact)
        }
    }

    private func parseKey(data armoredData: Data?, for email: String) -> Promise<Contact> {
        guard let data = armoredData else {
            return Promise(ContactsError.keyMissing)
        }

        do {
            let parsedKey = try core.parseKeys(armoredOrBinary: data)

            guard let keyDetail = parsedKey.keyDetails.first else {
                return Promise(ContactsError.unexpected("Key details are not parsed"))
            }

            let longids = parsedKey.keyDetails.flatMap { $0.ids }.map { $0.longid }

            let contact = Contact(
                email: email,
                name: keyDetail.users.first ?? email,
                pubKey: keyDetail.public,
                pubKeyLastSig: nil, // TODO: - will be provided later
                pubkeyLastChecked: Date(),
                pubkeyExpiresOn: nil, // TODO: - will be provided later
                longids: longids,
                lastUsed: nil
            )
            return Promise(contact)
        } catch let error {
            let message = "Armored or binary are not parsed.\n\(error.localizedDescription)"
            return Promise(ContactsError.unexpected(message))
        }
    }
}
