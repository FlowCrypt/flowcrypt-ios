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
}

protocol PublicKeyProvider {
    func retrievePubKeys(for email: String) -> [String]
    func removePubKey(with fingerprint: String, for email: String) throws
}

// MARK: - PROVIDER

struct ContactsService: ContactsServiceType {
    let localContactsProvider: LocalContactsProviderType
    let pubLookup: PubLookup

    init(
        localContactsProvider: LocalContactsProviderType,
        clientConfiguration: ClientConfiguration
    ) {
        self.localContactsProvider = localContactsProvider
        self.pubLookup = PubLookup(clientConfiguration: clientConfiguration)
    }
}

extension ContactsService: ContactsProviderType {
    func searchContact(with email: String) async throws -> RecipientWithSortedPubKeys {
        let contact = try await localContactsProvider.searchRecipient(with: email)
        guard let contact = contact else {
            let recipient = try await pubLookup.lookup(email: email)
            try localContactsProvider.save(recipient: recipient)
            return recipient
        }

        let recipient = try await pubLookup.lookup(email: email)
        try localContactsProvider.updateKeys(for: recipient)
        return contact
    }

    func searchContacts(query: String) -> [String] {
        localContactsProvider.searchEmails(query: query)
    }
}

extension ContactsService: PublicKeyProvider {
    func retrievePubKeys(for email: String) -> [String] {
        return localContactsProvider.retrievePubKeys(for: email)
    }

    func removePubKey(with fingerprint: String, for email: String) throws {
        try localContactsProvider.removePubKey(with: fingerprint, for: email)
    }
}
