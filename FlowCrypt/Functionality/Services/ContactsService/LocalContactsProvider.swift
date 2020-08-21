//
//  LocalContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol LocalContactsProviderType: ContactsServiceType {
    func save(contact: Contact)
    func retrievePubKey(for contact: Contact)
}

struct LocalContactsProvider: LocalContactsProviderType {
    func save(contact: Contact) {
        print("^^LocalContactsProvider \(#function)")
    }

    func retrievePubKey(for contact: Contact) {
        print("^^LocalContactsProvider \(#function)")
    }
}

extension LocalContactsProvider {
    func searchContact(with email: String) -> Promise<Contact> {
        Promise(ContactsError.keyMissing)
    }
}
