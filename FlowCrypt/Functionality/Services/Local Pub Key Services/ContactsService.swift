//
//  RecipientsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum ContactsError: Error {
    case keyMissing
    case unexpected(String)
}

protocol ContactsServiceType: PublicKeyProvider, ContactsProviderType {
}

protocol ContactsProviderType {
    func searchContact(with email: String) async throws -> RecipientWithSortedPubKeys
    func searchContacts(query: String) -> [String]
    func findBy(longId: String) async -> RecipientWithSortedPubKeys?
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
    func searchContact(with email: String) async throws -> RecipientWithSortedPubKeys {
        let contact = try await localContactsProvider.searchRecipient(with: email)
        guard let contact = contact else {
            let recipient = try await pubLookup.lookup(email: email)
            localContactsProvider.save(recipient: recipient)
            return recipient
        }

        let recipient = try await pubLookup.lookup(email: email)
        localContactsProvider.updateKeys(for: recipient)
        return contact
    }

    func searchContacts(query: String) -> [String] {
        localContactsProvider.searchEmails(query: query)
    }

    func findBy(longId: String) async -> RecipientWithSortedPubKeys? {
        await localContactsProvider.findBy(longid: longId)
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
