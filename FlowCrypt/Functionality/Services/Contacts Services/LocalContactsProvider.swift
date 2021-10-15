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
    func save(recipient: RecipientWithPubKeys)
    func remove(recipient: RecipientWithPubKeys)
    func getAllRecipients() -> [RecipientWithPubKeys]
}

struct LocalContactsProvider {
    private let localContactsCache: CacheService<RecipientObject>
    let core: Core

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage(),
        core: Core = .shared
    ) {
        self.localContactsCache = CacheService<RecipientObject>(encryptedStorage: encryptedStorage)
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
            .map { $0.key } ?? []
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

    func searchRecipient(with email: String) -> RecipientWithPubKeys? {
        guard let recipientObject = find(with: email) else { return nil }
        return RecipientWithPubKeys(recipientObject)
    }

    func getAllRecipients() -> [RecipientWithPubKeys] {
        localContactsCache.realm
            .objects(RecipientObject.self)
            .map { object in
                let keyDetails = object.pubKeys
                                    .compactMap { try? core.parseKeys(armoredOrBinary: $0.key.data()).keyDetails }
                                    .flatMap { $0 }
                return RecipientWithPubKeys(object, keyDetails: Array(keyDetails))
            }
            .sorted(by: { $0.email > $1.email })
    }

    func removePubKey(with fingerprint: String, for email: String) {
        find(with: email)?
            .pubKeys
            .filter { $0.fingerprint == fingerprint }
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
}
