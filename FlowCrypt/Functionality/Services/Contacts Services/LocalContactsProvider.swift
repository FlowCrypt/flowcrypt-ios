//
//  LocalContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises
import RealmSwift

protocol LocalContactsProviderType: PublicKeyProvider {
    func updateLastUsedDate(for email: String)
    func searchContact(with email: String) -> Contact?
    func save(contact: Contact)
    func remove(contact: Contact)
    func getAllContacts() -> [Contact]
    func remove(pubKey: String, for email: String)
}

struct LocalContactsProvider {
    private let localContactsCache: CacheService<ContactObject>
    let core: Core

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage(),
        core: Core = .shared
    ) {
        self.localContactsCache = CacheService<ContactObject>(encryptedStorage: encryptedStorage)
        self.core = core
    }
}

extension LocalContactsProvider: LocalContactsProviderType {
    func updateLastUsedDate(for email: String) {
        let contact = find(with: email)

        try? localContactsCache.realm.write {
            contact?.lastUsed = Date()
        }
    }

    func retrievePubKeys(for email: String) -> [String] {
        find(with: email)?.pubKeys
            .map { $0.key } ?? []
    }

    func save(contact: Contact) {
        localContactsCache.save(ContactObject(contact))
    }

    func remove(contact: Contact) {
        localContactsCache.remove(
            object: ContactObject(contact),
            with: contact.email
        )
    }

    func searchContact(with email: String) -> Contact? {
        guard let contactObject = find(with: email) else { return nil }
        return Contact(contactObject)
    }

    func getAllContacts() -> [Contact] {
        localContactsCache.realm
            .objects(ContactObject.self)
            .map { object in
                let keyDetails = object.pubKeys
                                    .compactMap { try? core.parseKeys(armoredOrBinary: $0.key.data()).keyDetails }
                                    .flatMap { $0 }
                return Contact(object, keyDetails: Array(keyDetails))
            }
            .sorted(by: { $0.email > $1.email })
    }

    func remove(pubKey: String, for email: String) {
        find(with: email)?
            .pubKeys
            .filter { $0.key == pubKey }
            .forEach { key in
                try? localContactsCache.realm.write {
                    localContactsCache.realm.delete(key)
                }
            }
    }
}

extension LocalContactsProvider {
    private func find(with email: String) -> ContactObject? {
        localContactsCache.realm.object(ofType: ContactObject.self,
                                        forPrimaryKey: email)
    }
}
