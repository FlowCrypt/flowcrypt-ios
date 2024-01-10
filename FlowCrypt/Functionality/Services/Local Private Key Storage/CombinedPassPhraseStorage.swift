//
//  CombinedPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

enum PassPhraseStorageMethod {
    case persistent, memory
}

// MARK: - Data Object
struct PassPhrase: Codable, Hashable, Equatable {
    let value: String
    let email: String
    let fingerprintsOfAssociatedKey: [String]
    let date: Date?

    var primaryFingerprintOfAssociatedKey: String {
        fingerprintsOfAssociatedKey[0]
    }

    init(value: String, email: String, fingerprintsOfAssociatedKey: [String], date: Date? = nil) {
        self.value = value
        self.email = email
        self.fingerprintsOfAssociatedKey = fingerprintsOfAssociatedKey
        self.date = date
    }

    func withUpdatedDate() -> Self {
        .init(
            value: self.value,
            email: self.email,
            fingerprintsOfAssociatedKey: self.fingerprintsOfAssociatedKey,
            date: Date()
        )
    }

    // We still need == operator here because we use `withUpdatedDate` to set `date` field to up-to-date
    // Therfore, 2 passphrases might be treated differently even though
    // they are exactly same if we don't implement custom == operator
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.primaryFingerprintOfAssociatedKey == rhs.primaryFingerprintOfAssociatedKey
            && lhs.value == rhs.value
            && lhs.email == rhs.email
    }

    // similarly here
    func hash(into hasher: inout Hasher) {
        hasher.combine(primaryFingerprintOfAssociatedKey)
    }
}

extension PassPhrase {
    init?(keypair: KeypairRealmObject) {
        guard let user = keypair.user, let passphrase = keypair.passphrase else { return nil }

        self.init(value: passphrase,
                  email: user.email,
                  fingerprintsOfAssociatedKey: Array(keypair.allFingerprints))
    }
}

// MARK: - Pass Phrase Storage
protocol PassPhraseStorageType {
    func save(passPhrase: PassPhrase) throws
    func update(passPhrase: PassPhrase) throws
    func remove(passPhrase: PassPhrase) throws
    func removePassPhrases(for email: String) throws

    func getPassPhrases(for email: String, expirationInSeconds: Int?) throws -> [PassPhrase]
}

// MARK: - CombinedPassPhraseStorage
protocol CombinedPassPhraseStorageType {
    var clientConfiguration: ClientConfiguration? { get set }
    func getPassPhrases(for email: String) throws -> [PassPhrase]
    func savePassPhrase(with passPhrase: PassPhrase, storageMethod: PassPhraseStorageMethod) throws
    func updatePassPhrase(with passPhrase: PassPhrase, storageMethod: PassPhraseStorageMethod) throws
    func savePassPhrasesInMemory(for email: String, _ passPhrase: String, privateKeys: [Keypair]) throws
}

final class CombinedPassPhraseStorage: CombinedPassPhraseStorageType {
    private lazy var logger = Logger.nested(Self.self)

    var clientConfiguration: ClientConfiguration?
    let encryptedStorage: PassPhraseStorageType
    let inMemoryStorage: PassPhraseStorageType

    init(
        encryptedStorage: PassPhraseStorageType,
        inMemoryStorage: PassPhraseStorageType = InMemoryPassPhraseStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.inMemoryStorage = inMemoryStorage
    }

    func savePassPhrase(with passPhrase: PassPhrase, storageMethod: PassPhraseStorageMethod) throws {
        logger.logInfo("\(storageMethod): saving passphrase for key \(passPhrase.primaryFingerprintOfAssociatedKey)")
        switch storageMethod {
        case .persistent:
            try encryptedStorage.save(passPhrase: passPhrase)
        case .memory:
            let storedPassPhrases = try encryptedStorage.getPassPhrases(for: passPhrase.email, expirationInSeconds: nil)
            let fingerprint = passPhrase.primaryFingerprintOfAssociatedKey
            if storedPassPhrases.contains(where: { $0.primaryFingerprintOfAssociatedKey == fingerprint }) {
                logger.logInfo("\(PassPhraseStorageMethod.persistent): removing pass phrase for key \(fingerprint)")
                try encryptedStorage.remove(passPhrase: passPhrase)
            }
            try inMemoryStorage.save(passPhrase: passPhrase)
        }
    }

    func updatePassPhrase(with passPhrase: PassPhrase, storageMethod: PassPhraseStorageMethod) throws {
        logger.logInfo("\(storageMethod): updating passphrase for key \(passPhrase.primaryFingerprintOfAssociatedKey)")
        switch storageMethod {
        case .persistent:
            try encryptedStorage.update(passPhrase: passPhrase)
        case .memory:
            try inMemoryStorage.save(passPhrase: passPhrase)
        }
    }

    func getPassPhrases(for email: String) throws -> [PassPhrase] {
        try encryptedStorage.getPassPhrases(
            for: email,
            expirationInSeconds: nil
        ) + inMemoryStorage.getPassPhrases(
            for: email,
            expirationInSeconds: clientConfiguration?.passphraseSessionLengthInSeconds
        )
    }

    func savePassPhrasesInMemory(for email: String, _ passPhrase: String, privateKeys: [Keypair]) throws {
        for privateKey in privateKeys {
            let pp = PassPhrase(
                value: passPhrase,
                email: email,
                fingerprintsOfAssociatedKey: privateKey.allFingerprints
            )
            try savePassPhrase(with: pp, storageMethod: .memory)
        }
    }
}
