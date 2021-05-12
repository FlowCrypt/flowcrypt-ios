//
//  RecipientsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

enum ContactsError: Error {
    case keyMissing
    case unexpected(String)
}

protocol ContactsServiceType: PublicKeyProvider, ContactsProviderType {
}

protocol PublicKeyProvider {
    func retrievePubKey(for email: String) -> String?
}

// MARK: - PROVIDER

struct ContactsService: ContactsServiceType {
    let localContactsProvider: LocalContactsProviderType
    let remoteContactsProvider: ContactsProviderType

    init(
        localContactsProvider: LocalContactsProviderType = LocalContactsProvider(storage: DataService.shared.storage),
        remoteContactsProvider: ContactsProviderType = RemoteContactsProvider()
    ) {
        self.localContactsProvider = localContactsProvider
        self.remoteContactsProvider = remoteContactsProvider
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
        remoteContactsProvider
            .searchContact(with: email)
            .then { contact in
                self.localContactsProvider.save(contact: contact)
            }
    }
}

extension ContactsService: PublicKeyProvider {
    func retrievePubKey(for email: String) -> String? {
        let publicKey = localContactsProvider.retrievePubKey(for: email)
        localContactsProvider.updateLastUsedDate(for: email)
        return publicKey
    }
}
