//
//  RecipientsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol ContactsServiceType {
    func searchContact(with email: String)
}

// MARK: - LOCAL
protocol LocalContactsProviderType: ContactsServiceType {
    func save(contact: Contact)
    func retrievePubKey(for contact: Contact)
}

struct LocalContactsProvider: LocalContactsProviderType {
    func searchContact(with email: String) {
        print("^^LocalContactsProvider \(#function)")
    }

    func save(contact: Contact) {
        print("^^LocalContactsProvider \(#function)")
    }

    func retrievePubKey(for contact: Contact) {
        print("^^LocalContactsProvider \(#function)")
    }
}

// MARK: - REMOTE
extension AttesterApi: ContactsServiceType {
    func searchContact(with email: String) {
        print("^^AttesterApi \(#function)")
    }
}

// MARK: - PROVIDER
struct ContactsService: ContactsServiceType {
    let attesterApi = AttesterApi()
    let core = Core.shared
    #warning("Remove")
    let ds = DataService.shared

    let localContactsProvider: LocalContactsProviderType
    let remoteContactsProvider: ContactsServiceType

    init(
        localContactsProvider: LocalContactsProviderType = LocalContactsProvider(),
        remoteContactsProvider: ContactsServiceType = AttesterApi()
    ) {
        self.localContactsProvider = localContactsProvider
        self.remoteContactsProvider = remoteContactsProvider
    }

    func searchContact(with email: String) {
        print("^^ ContactsProvider \(#function)")

        try? ds.storage.write {
            ds.storage.add(ContactObjectTest8(
                email: "email",
                name: nil,
                pubKey: "pubKey1_new",
                pubKeyLastSig: nil,
                pubkeyLastChecked: nil,
                pubkeyExpiresOn: Date(),
                lastUsed: nil,
                longids: ["longid 1", "longid 2"]
                ), update: .modified
            )
            print(Array(ds.storage.objects(ContactObjectTest8.self)))
        }

        let foundLocal = false
        localContactsProvider.searchContact(with: email)
        if foundLocal {
            print("^^ return contact")
        } else {
            let foundRemote = true
            remoteContactsProvider.searchContact(with: email)

            if foundRemote {
                print("^^ return contact")
                // localContactsProvider.save(contact: )
            } else {
                print("^^ return error")
            }
        }

//        attesterApi
//            .lookupEmailTest(email: "cryptup.tester@gmail.com")
//            .then { result in
//                print("^^ \(result!.toStr())")
//
//                do {
//                    let parsed = try self.core.parseKeys(armoredOrBinary: result!)
//                    print("^^ \(parsed)")
//
//                } catch let e {
//                    print("^^ \(e)")
//                }
//        }.catch { e in
//            print("^^ \(e)")
//        }
    }
}

/*
 [CoreRes.ParseKeys]
        let keyDetails: [KeyDetails]
            struct KeyDetails: Decodable {
                let `public`: String
                let `private`: String? // ony if this is prv
                let isFullyDecrypted: Bool? // only if this is prv
                let isFullyEncrypted: Bool? // only if this is prv
                let ids: [KeyId]
                let created: Int
                let users: [String]
            }
 */

import RealmSwift

final class LongId: Object {
    @objc dynamic var value: String = ""

    convenience init(value: String) {
        self.init()
        self.value = value
    }
}

final class ContactObjectTest8: Object {
    @objc dynamic var email: String = ""
    @objc dynamic var pubKey: String = ""

    @objc dynamic var name: String?

    @objc dynamic var pubkeyExpiresOn: Date!
    @objc dynamic var pubKeyLastSig: Date?
    @objc dynamic var pubkeyLastChecked: Date?
    @objc dynamic var lastUsed: Date?

    let longids = List<LongId>()

    override class func primaryKey() -> String? { "email" }

    convenience init(
        email: String,
        name: String?,
        pubKey: String,
        pubKeyLastSig: Date?,
        pubkeyLastChecked: Date?,
        pubkeyExpiresOn: Date,
        lastUsed: Date?,
        longids: [String]
    ) {
        self.init()
        self.email = email
        self.name = name ?? ""
        self.pubKey = pubKey
        self.pubkeyExpiresOn = pubkeyExpiresOn
        self.pubKeyLastSig = pubKeyLastSig
        self.pubkeyLastChecked = pubkeyLastChecked
        self.lastUsed = lastUsed

        longids
            .map(LongId.init)
            .forEach {
                self.longids.append($0)
            }
    }

}

struct Contact {
    let email: String
    /// name if known
    let name: String?
    /// public key
    let pubKey: String
    /// will be provided later
    let pubKeyLastSig: Date?
    /// the date when pubkey was retrieved from Attester, or nil
    let pubkeyLastChecked: Date?
    /// pubkey expiration date
    let pubkeyExpiresOn: Date
    /// all pubkey longids, comma-separated
    let longids: [String]
    /// last time an email was sent to this contact, update when email is sent
    let lastUsed: Date?
    
    var longid: String { longids.first }
}

extension Contact {
    init(_ contactObject: ContactObjectTest8) {
        self.email = contactObject.email
        self.name = contactObject.name.nilIfEmpty
        self.pubKey = contactObject.pubKey
        self.pubKeyLastSig = contactObject.pubKeyLastSig
        self.pubkeyLastChecked = contactObject.pubkeyLastChecked
        self.pubkeyExpiresOn = contactObject.pubkeyExpiresOn
        self.lastUsed = contactObject.lastUsed
        self.longids = contactObject.longids.map { $0.value }
    }
}

extension Optional where Wrapped == String {
    var nilIfEmpty: String? {
        guard let strongSelf = self else {
            return nil
        }
        return strongSelf.isEmpty ? nil : strongSelf
    }
}

/*
 When a recipient is evaluated (see issue #201 )

 first search local contacts for public key
    if found, use the local contact
    if not found, search on attester
        if pubkey found on attester, save the public key in local contacts (TOFU - Trust on First Use)

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
