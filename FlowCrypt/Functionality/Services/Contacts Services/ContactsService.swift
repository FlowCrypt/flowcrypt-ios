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
    func searchContact(with email: String) -> Promise<Contact>
}

protocol PublicKeyProvider {
    func retrievePubKeys(for email: String) -> [String]
    func remove(pubKey: ContactKey, for email: String)
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
    func searchContact(with email: String) -> Promise<Contact> {
        guard let contact = localContactsProvider.searchContact(with: email) else {
            return searchRemote(for: email)
        }
        return Promise(contact)
    }

    private func searchRemote(for email: String) -> Promise<Contact> {
        pubLookup
            .lookup(with: email)
            .then { contact in
                self.localContactsProvider.save(contact: contact)
            }
    }
}

extension ContactsService: PublicKeyProvider {
    func retrievePubKeys(for email: String) -> [String] {
        let publicKeys = localContactsProvider.retrievePubKeys(for: email)
        localContactsProvider.updateLastUsedDate(for: email)
        return publicKeys
    }

    func remove(pubKey: ContactKey, for email: String) {
        //let keys = retrievePubKeys(for: email).filter { $0 != pubKey }
    }
}
