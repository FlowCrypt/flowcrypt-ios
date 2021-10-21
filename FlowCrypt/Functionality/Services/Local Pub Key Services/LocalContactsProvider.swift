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
    func searchRecipient(with email: String) -> RecipientWithPubKeys?
    func searchEmails(query: String) -> [String]
    func save(recipient: RecipientWithPubKeys)
    func remove(recipient: RecipientWithPubKeys)
    func updateKeys(for recipient: RecipientWithPubKeys)
    func getAllRecipients() -> [RecipientWithPubKeys]
}

struct LocalContactsProvider {
    private let localContactsCache: EncryptedCacheService<RecipientObject>
    let core: Core

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage(),
        core: Core = .shared
    ) {
        self.localContactsCache = EncryptedCacheService<RecipientObject>(encryptedStorage: encryptedStorage)
        self.core = core
    }
}

extension LocalContactsProvider: LocalContactsProviderType {
    func updateLastUsedDate(for email: String) {
        let recipient = find(with: email)

        try? localContactsCache.realm.write {
            recipient?.lastUsed = Date()
        }
    }

    func retrievePubKeys(for email: String) -> [String] {
        find(with: email)?.pubKeys
            .map { $0.armored } ?? []
    }

    func save(recipient: RecipientWithPubKeys) {
        localContactsCache.save(RecipientObject(recipient))
    }

    func remove(recipient: RecipientWithPubKeys) {
        localContactsCache.remove(
            object: RecipientObject(recipient),
            with: recipient.email
        )
    }

    func updateKeys(for recipient: RecipientWithPubKeys) {
        guard let recipientObject = find(with: recipient.email) else {
            localContactsCache.save(RecipientObject(recipient))
            return
        }

        recipient.pubKeys
            .forEach { pubKey in
                if let index = recipientObject.pubKeys.firstIndex(where: { $0.primaryFingerprint == pubKey.fingerprint }) {
                    update(pubKey: pubKey, for: recipientObject, at: index)
                } else {
                    add(pubKey: pubKey, to: recipientObject)
                }
            }
    }

    func searchRecipient(with email: String) -> RecipientWithPubKeys? {
        guard let recipientObject = find(with: email) else { return nil }
        return RecipientWithPubKeys(recipientObject)
    }

    func searchEmails(query: String) -> [String] {
        localContactsCache.realm
            .objects(RecipientObject.self)
            .filter("email contains[c] %@", query)
            .map(\.email)
    }

    func getAllRecipients() -> [RecipientWithPubKeys] {
        localContactsCache.realm
            .objects(RecipientObject.self)
            .map { object in
                let keyDetails = object.pubKeys
                                    .compactMap { try? core.parseKeys(armoredOrBinary: $0.armored.data()).keyDetails }
                                    .flatMap { $0 }
                return RecipientWithPubKeys(object, keyDetails: Array(keyDetails))
            }
            .sorted(by: { $0.email > $1.email })
    }

    func removePubKey(with fingerprint: String, for email: String) {
        find(with: email)?
            .pubKeys
            .filter { $0.primaryFingerprint == fingerprint }
            .forEach { key in
                try? localContactsCache.realm.write {
                    localContactsCache.realm.delete(key)
                }
            }
    }
}

extension LocalContactsProvider {
    private func find(with email: String) -> RecipientObject? {
        localContactsCache.realm.object(ofType: RecipientObject.self,
                                        forPrimaryKey: email)
    }

    private func add(pubKey: PubKey, to recipient: RecipientObject) {
        guard let pubKeyObject = try? PubKeyObject(pubKey) else { return }
        try? localContactsCache.realm.write {
            recipient.pubKeys.append(pubKeyObject)
        }
    }

    private func update(pubKey: PubKey, for recipient: RecipientObject, at index: Int) {
        guard let existingKeyLastSig = recipient.pubKeys[index].lastSig,
              let updateKeyLastSig = pubKey.lastSig,
              updateKeyLastSig > existingKeyLastSig
        else { return }

        try? localContactsCache.realm.write {
            recipient.pubKeys[index].update(from: pubKey)
        }
    }
}
