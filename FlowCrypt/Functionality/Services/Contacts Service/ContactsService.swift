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
    func findLocalContact(with email: String) async throws -> RecipientWithSortedPubKeys?
    func searchLocalContacts(query: String) throws -> [RecipientBase]
    func fetchContact(_ contact: Recipient) async throws -> RecipientWithSortedPubKeys
}

protocol PublicKeyProvider {
    func retrievePubKeys(for email: String) throws -> [String]
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
    func findLocalContact(with email: String) async throws -> RecipientWithSortedPubKeys? {
        return try await localContactsProvider.searchRecipient(with: email)
    }

    func searchLocalContacts(query: String) throws -> [RecipientBase] {
        try localContactsProvider.searchRecipients(query: query)
    }

    func fetchContact(_ recipient: Recipient) async throws -> RecipientWithSortedPubKeys {
        let lookupRecipient = try await pubLookup.lookup(recipient: recipient)
        try localContactsProvider.updateKeys(for: lookupRecipient)
        return lookupRecipient
    }
}

extension ContactsService: PublicKeyProvider {
    func retrievePubKeys(for email: String) throws -> [String] {
        try localContactsProvider.retrievePubKeys(for: email)
    }

    func removePubKey(with fingerprint: String, for email: String) throws {
        try localContactsProvider.removePubKey(with: fingerprint, for: email)
    }
}
