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
    func retrievePubKey(for email: String) -> String? {
        nil
    }

    func save(contact: Contact) {
        print("^^LocalContactsProvider \(#function)")
    }

    func searchContact(with email: String) -> Contact? {
        storage.objects(ContactObject.self)
            .first(where: { $0.email == email })
            .map(Contact.init)
    }
}

//        try? ds.storage.write {
//            ds.storage.add(ContactObjectTest8(
//                email: "email",
//                name: nil,
//                pubKey: "pubKey1_new",
//                pubKeyLastSig: nil,
//                pubkeyLastChecked: nil,
//                pubkeyExpiresOn: Date(),
//                lastUsed: nil,
//                longids: ["longid 1", "longid 2"]
//                ), update: .modified
//            )
//            print(Array(ds.storage.objects(ContactObjectTest8.self)))
//        }
