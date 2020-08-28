//
//  LocalContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
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
}

struct LocalContactsProvider: CacheServiceType {
    let storage: CacheStorage
    let localCache: CacheService<ContactObject>

    init(storage: @escaping @autoclosure () -> Realm) {
        self.storage = storage
        self.localCache = CacheService(storage: storage())
    }
}

extension LocalContactsProvider: LocalContactsProviderType {
    func updateLastUsedDate(for email: String) {
        let realm = storage()
        let contact = realm
            .objects(ContactObject.self)
            .first(where: { $0.email == email })

        try? realm.write {
            contact?.lastUsed = Date()
        }
    }

    func retrievePubKey(for email: String) -> String? {
        storage()
            .objects(ContactObject.self)
            .first(where: { $0.email == email })?
            .pubKey
    }

    func save(contact: Contact) {
        localCache.save(ContactObject(contact: contact))
//        let realm = storage()
//        try? realm.write {
//            realm.add(
//                ContactObject(contact: contact),
//                update: .modified
//            )
//        }
    }

    func remove(contact: Contact) {
        let realm = storage()
        let contactToDelete = realm.objects(ContactObject.self)
            .first(where: { $0.email == contact.email })

        guard let contact = contactToDelete else { return }

        try? realm.write {
           realm.delete(contact)
        }
    }

    func searchContact(with email: String) -> Contact? {
        storage()
            .objects(ContactObject.self)
            .first(where: { $0.email == email })
            .map(Contact.init)
    }

    func getAllContacts() -> [Contact] {
        Array(storage()
            .objects(ContactObject.self)
            .map(Contact.init)
        )
    }
}
