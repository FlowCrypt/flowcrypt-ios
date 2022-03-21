//
//  LocalContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift
import FlowCryptCommon

enum ContactsError: Error {
    case keyMissing
    case unexpected(String)
}

protocol PublicKeyProvider {
    func retrievePubKeys(for email: String) throws -> [String]
    func removePubKey(with fingerprint: String, for email: String) throws
}

protocol LocalContactsProviderType: PublicKeyProvider {
    func searchRecipient(with email: String) async throws -> RecipientWithSortedPubKeys?
    func searchRecipients(query: String) throws -> [Recipient]
    func save(recipient: RecipientWithSortedPubKeys) throws
    func remove(recipient: RecipientWithSortedPubKeys) throws
    func updateKeys(for recipient: RecipientWithSortedPubKeys) throws
    func getAllRecipients() async throws -> [RecipientWithSortedPubKeys]
}

final class LocalContactsProvider {
    private let encryptedStorage: EncryptedStorageType
    private let core: Core

    private lazy var logger = Logger.nested(Self.self)

    private var storage: Realm {
        get throws {
            try encryptedStorage.storage
        }
    }

    init(
        encryptedStorage: EncryptedStorageType,
        core: Core = .shared
    ) {
        self.encryptedStorage = encryptedStorage
        self.core = core
    }
}

extension LocalContactsProvider: LocalContactsProviderType {
    func retrievePubKeys(for email: String) throws -> [String] {
        guard let object = try find(with: email) else { return [] }

        do {
            try storage.write {
                object.lastUsed = Date()
            }
        } catch {
            logger.logError("fail to update last used property \(error)")
        }

        return object.pubKeys.map(\.armored)
    }

    func save(recipient: RecipientWithSortedPubKeys) throws {
        try save(RecipientRealmObject(recipient))
    }

    func remove(recipient: RecipientWithSortedPubKeys) throws {
        guard let object = try find(with: recipient.email) else {
            return
        }

        let storage = try storage
        try storage.write {
            storage.delete(object)
        }
    }

    func updateKeys(for recipient: RecipientWithSortedPubKeys) throws {
        guard let recipientObject = try find(with: recipient.email) else {
            try save(RecipientRealmObject(recipient))
            return
        }

        try recipient.pubKeys
            .forEach { pubKey in
                if let index = recipientObject.pubKeys.firstIndex(where: { $0.primaryFingerprint == pubKey.fingerprint }) {
                    try update(pubKey: pubKey, for: recipientObject, at: index)
                } else {
                    try add(pubKey: pubKey, to: recipientObject)
                }
            }
    }

    func searchRecipient(with email: String) async throws -> RecipientWithSortedPubKeys? {
        guard let recipient = try find(with: email).map(Recipient.init) else { return nil }
        return try await parseRecipient(from: recipient)
    }

    func searchRecipients(query: String) throws -> [Recipient] {
        try storage
            .objects(RecipientRealmObject.self)
            .filter("email contains[c] %@", query)
            .map(Recipient.init)
    }

    func getAllRecipients() async throws -> [RecipientWithSortedPubKeys] {
        let objects: [Recipient] = try storage.objects(RecipientRealmObject.self)
            .map(Recipient.init)
        var recipients: [RecipientWithSortedPubKeys] = []
        for object in objects {
            recipients.append(try await parseRecipient(from: object))
        }
        return recipients.sorted(by: { $0.email > $1.email })
    }

    func removePubKey(with fingerprint: String, for email: String) throws {
        let storage = try storage

        try find(with: email)?
            .pubKeys
            .filter { $0.primaryFingerprint == fingerprint }
            .forEach { key in
                try storage.write {
                    storage.delete(key)
                }
            }
    }
}

extension LocalContactsProvider {
    private func find(with email: String) throws -> RecipientRealmObject? {
        try storage.object(ofType: RecipientRealmObject.self, forPrimaryKey: email)
    }

    private func save(_ object: RecipientRealmObject) throws {
        let storage = try storage
        try storage.write {
            storage.add(object, update: .modified)
        }
    }

    private func parseRecipient(from recipient: Recipient) async throws -> RecipientWithSortedPubKeys {
        let armoredToParse = recipient.pubKeys
            .map(\.armored)
            .joined(separator: "\n")
        let parsed = try await core.parseKeys(armoredOrBinary: armoredToParse.data())
        return RecipientWithSortedPubKeys(recipient, keyDetails: parsed.keyDetails)
    }

    private func add(pubKey: PubKey, to recipient: RecipientRealmObject) throws {
        let pubKeyObject = try PubKeyRealmObject(pubKey)
        try storage.write {
            recipient.pubKeys.append(pubKeyObject)
        }
    }

    private func update(pubKey: PubKey, for recipient: RecipientRealmObject, at index: Int) throws {
        guard
            let existingKeyLastSig = recipient.pubKeys[index].lastSig,
            let updateKeyLastSig = pubKey.lastSig,
            updateKeyLastSig > existingKeyLastSig
        else {
            return
        }

        try storage.write {
            recipient.pubKeys[index].update(from: pubKey)
        }
    }
}
