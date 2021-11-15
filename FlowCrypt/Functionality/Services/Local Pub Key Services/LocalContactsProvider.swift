//
//  LocalContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

protocol LocalContactsProviderType: PublicKeyProvider {
    func updateLastUsedDate(for email: String)
    func searchRecipient(with email: String) async throws -> RecipientWithSortedPubKeys?
    func searchEmails(query: String) -> [String]
    func findBy(longid: String) async -> RecipientWithSortedPubKeys?
    func save(recipient: RecipientWithSortedPubKeys)
    func remove(recipient: RecipientWithSortedPubKeys)
    func updateKeys(for recipient: RecipientWithSortedPubKeys)
    func getAllRecipients() async throws -> [RecipientWithSortedPubKeys]
}

struct LocalContactsProvider {
    private let localContactsCache: EncryptedCacheService<RecipientRealmObject>
    let core: Core

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage(),
        core: Core = .shared
    ) {
        self.localContactsCache = EncryptedCacheService<RecipientRealmObject>(encryptedStorage: encryptedStorage)
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
        find(with: email)?.pubKeys.map(\.armored) ?? []
    }

    func findBy(longid: String) async -> RecipientWithSortedPubKeys? {
        if let object = localContactsCache.realm
            .objects(RecipientObject.self)
            .first(where: { $0.contains(longid: longid) }) {
            return try? await parseRecipient(from: object.freeze())
        }

        return nil
    }

    func save(recipient: RecipientWithSortedPubKeys) {
        localContactsCache.save(RecipientRealmObject(recipient))
    }

    func remove(recipient: RecipientWithSortedPubKeys) {
        localContactsCache.remove(
            object: RecipientRealmObject(recipient),
            with: recipient.email
        )
    }

    func updateKeys(for recipient: RecipientWithSortedPubKeys) {
        guard let recipientObject = find(with: recipient.email) else {
            localContactsCache.save(RecipientRealmObject(recipient))
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

    func searchRecipient(with email: String) async throws -> RecipientWithSortedPubKeys? {
        guard let recipientObject = find(with: email) else { return nil }
        return try await parseRecipient(from: recipientObject.detached())
    }

    func searchEmails(query: String) -> [String] {
        localContactsCache.realm
            .objects(RecipientRealmObject.self)
            .filter("email contains[c] %@", query)
            .map(\.email)
    }

    func getAllRecipients() async throws -> [RecipientWithSortedPubKeys] {
        let objects = localContactsCache.realm.objects(RecipientRealmObject.self).detached
        var recipients: [RecipientWithSortedPubKeys] = []
        for object in objects {
            recipients.append(try await parseRecipient(from: object))
        }
        return recipients.sorted(by: { $0.email > $1.email })
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
    private func find(with email: String) -> RecipientRealmObject? {
        localContactsCache.realm.object(ofType: RecipientRealmObject.self,
                                        forPrimaryKey: email)
    }

    private func parseRecipient(from object: RecipientRealmObject) async throws -> RecipientWithSortedPubKeys {
        let armoredToParse = object.pubKeys
            .map { $0.armored }
            .joined(separator: "\n")
        let parsed = try await core.parseKeys(armoredOrBinary: armoredToParse.data())
        return RecipientWithSortedPubKeys(object, keyDetails: parsed.keyDetails)
    }

    private func add(pubKey: PubKey, to recipient: RecipientRealmObject) {
        guard let pubKeyObject = try? PubKeyRealmObject(pubKey) else { return }
        try? localContactsCache.realm.write {
            recipient.pubKeys.append(pubKeyObject)
        }
    }

    private func update(pubKey: PubKey, for recipient: RecipientRealmObject, at index: Int) {
        guard let existingKeyLastSig = recipient.pubKeys[index].lastSig,
              let updateKeyLastSig = pubKey.lastSig,
              updateKeyLastSig > existingKeyLastSig
        else { return }

        try? localContactsCache.realm.write {
            recipient.pubKeys[index].update(from: pubKey)
        }
    }
}
