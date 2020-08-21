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

protocol LocalContactsProviderType: ContactsServiceType {
    func updateLastUsedDate(for email: String)
    func searchContact(with email: String) -> Contact?
    func save(contact: Contact)
}

struct LocalContactsProvider {
    let storage: Realm

    init(storage: Realm = DataService.shared.storage) {
        self.storage = storage
    }
}

extension LocalContactsProvider: LocalContactsProviderType {
    func updateLastUsedDate(for email: String) {
        let contact = storage.objects(ContactObject.self)
            .first(where: { $0.email == email })

        try? storage.write {
            contact?.lastUsed = Date()
        }
    }

    func retrievePubKey(for email: String) -> String? {
        storage.objects(ContactObject.self)
            .first(where: { $0.email == email })?
            .pubKey
    }

    func save(contact: Contact) {
        try? storage.write {
            storage.add(
                ContactObject(contact: contact),
                update: .modified
            )
        }
    }

    func searchContact(with email: String) -> Contact? {
        storage.objects(ContactObject.self)
            .first(where: { $0.email == email })
            .map(Contact.init)
    }
}
