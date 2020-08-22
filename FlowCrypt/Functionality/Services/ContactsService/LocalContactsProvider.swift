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
}

struct LocalContactsProvider {
    let storage: () -> Realm

    init(storage: @escaping @autoclosure () -> Realm) {
        self.storage = storage
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
        let realm = storage()
        try? realm.write {
            realm.add(
                ContactObject(contact: contact),
                update: .modified
            )
        }
    }

    func searchContact(with email: String) -> Contact? {
        storage()
            .objects(ContactObject.self)
            .first(where: { $0.email == email })
            .map(Contact.init)
    }
}
