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

// MARK: - PROVIDER
protocol ContactsServiceType {
    func searchContact(with email: String) -> Promise<Contact>
}

struct ContactsService: ContactsServiceType {
    #warning("Remove")
    let ds = DataService.shared

    let localContactsProvider: LocalContactsProviderType
    let remoteContactsProvider: ContactsServiceType

    init(
        localContactsProvider: LocalContactsProviderType = LocalContactsProvider(),
        remoteContactsProvider: ContactsServiceType = RemoteContactsProvider()
    ) {
        self.localContactsProvider = localContactsProvider
        self.remoteContactsProvider = remoteContactsProvider
    }

    func searchContact(with email: String) -> Promise<Contact> {
        print("^^ ContactsProvider \(#function)")

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

        let foundLocal = false
        localContactsProvider.searchContact(with: email)
        if foundLocal {
            print("^^ return contact")
        } else {
            let foundRemote = false
            remoteContactsProvider.searchContact(with: email)

            if foundRemote {
                print("^^ return contact")
                // localContactsProvider.save(contact: )
            } else {
                print("^^ return error")
            }
        }
        return Promise(ContactsError.keyMissing)
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
