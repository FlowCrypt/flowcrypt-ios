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

protocol ContactsServiceType {
    func retrievePubKey(for email: String) -> String?
}

// MARK: - PROVIDER

struct ContactsService {
    let localContactsProvider: LocalContactsProviderType
    let remoteContactsProvider: ContactsProviderType

    init(
        localContactsProvider: LocalContactsProviderType = LocalContactsProvider(),
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

extension ContactsService: ContactsServiceType {
    func retrievePubKey(for email: String) -> String? {
        nil
    }
}

/*
 When a recipient is evaluated (see issue #201 )

 first search local contacts for public key
    if found, use the local contact

 if not found, search on attester
    if pubkey found on attester,
    save the public key in local contacts (TOFU - Trust on First Use)

 later when I hit the send button, the public key will be fetched locally from Contacts.
 If there are none, it will show alert that recipient doesn't use pgp.



 When saving contacts, the following info needs to be saved, as a Realm object:

 type Contact = {
   email: string; // lowercased, trimmed email address
   name: string | null; // name if known, else null
   searchIndex: string; // this will be used to search contacts, and will be: `\(email) \(name)` lowercased. You can skip this if Realm can do a composed query such as `WHERE email CONTAINS "tom" OR name CONTAINS "tom"`.
   pubkey: string | null; // armored public key, or null if we don't know pubkey
   pubkeyLastSig: Date  | null; // todo for tom - I'll give you a way to get this
   pubkeyLastChecked: number | null; // the date when pubkey was retrieved from Attester, or null if none
   pubkeyExpiresOn: number | null; // pubkey expiration date
   longid: string | null; // first pubkey longid
   longids: string | null; // all pubkey longids, comma-separated
   lastUsed: Date | null; // last time an email was sent to this contact, update when email is sent (will be used to order contact results)
 };

 For now, we only support sending emails to users who DO have a public key.
 Therefore, we'll only store a contact if we already know their public key.
 */
