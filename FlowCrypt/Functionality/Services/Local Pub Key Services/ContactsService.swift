//
//  RecipientsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

enum ContactsError: Error {
    case keyMissing
    case unexpected(String)
}

protocol ContactsServiceType: PublicKeyProvider, ContactsProviderType {
}

protocol ContactsProviderType {
    func searchContact(with email: String) -> Promise<RecipientWithPubKeys>
}

protocol PublicKeyProvider {
    func retrievePubKeys(for email: String) -> [String]
    func removePubKey(with fingerprint: String, for email: String)
}

// MARK: - PROVIDER

struct ContactsService: ContactsServiceType {
    let localContactsProvider: LocalContactsProviderType
    let pubLookup: PubLookupType

    init(
        localContactsProvider: LocalContactsProviderType = LocalContactsProvider(),
        pubLookup: PubLookupType = PubLookup()
    ) {
        self.localContactsProvider = localContactsProvider
        self.pubLookup = pubLookup
    }
}

extension ContactsService: ContactsProviderType {
    func searchContact(with email: String) -> Promise<RecipientWithPubKeys> {
        guard let contact = localContactsProvider.searchRecipient(with: email) else {
            return pubLookup.lookup(with: email).then { recipient in
                localContactsProvider.save(recipient: recipient)
            }
        }
        pubLookup.lookup(with: email).then { recipient in
            localContactsProvider.updateKeys(for: recipient)
        }
        return Promise(contact)
    }

}

extension ContactsService: PublicKeyProvider {
    func retrievePubKeys(for email: String) -> [String] {
        let publicKeys = localContactsProvider.retrievePubKeys(for: email)
        localContactsProvider.updateLastUsedDate(for: email)
        return publicKeys
    }

    func removePubKey(with fingerprint: String, for email: String) {
        localContactsProvider.removePubKey(with: fingerprint, for: email)
    }
}
