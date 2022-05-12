//
//  PassPhraseStorageService.swift
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
    let fingerprintsOfAssociatedKey: [String]
    let date: Date?

    var primaryFingerprintOfAssociatedKey: String {
        fingerprintsOfAssociatedKey[0]
    }

    init(value: String, fingerprintsOfAssociatedKey: [String], date: Date? = nil) {
        self.value = value
        self.fingerprintsOfAssociatedKey = fingerprintsOfAssociatedKey
        self.date = date
    }

    func withUpdatedDate() -> PassPhrase {
        PassPhrase(value: self.value, fingerprintsOfAssociatedKey: self.fingerprintsOfAssociatedKey, date: Date())
    }

    // (tom) todo - this is a confusing thing to do
    // when comparing pass phrases to one another, you would expect that it's compared by the pass phrase string
    // itself, and not by primary fingerprint of the associated key. I understand this is being used somewhere,
    // but I suggest to refactor it to avoid defining this == overload.
    static func == (lhs: PassPhrase, rhs: PassPhrase) -> Bool {
        lhs.primaryFingerprintOfAssociatedKey == rhs.primaryFingerprintOfAssociatedKey
    }

    // similarly here
    func hash(into hasher: inout Hasher) {
        hasher.combine(primaryFingerprintOfAssociatedKey)
    }
}

extension PassPhrase {
    init?(keypair: KeypairRealmObject) {
        guard let passphrase = keypair.passphrase else { return nil }

        self.init(value: passphrase,
                  fingerprintsOfAssociatedKey: Array(keypair.allFingerprints))
    }
}

// MARK: - Pass Phrase Storage
protocol PassPhraseStorageType {
    func save(passPhrase: PassPhrase) throws
    func update(passPhrase: PassPhrase) throws
    func remove(passPhrase: PassPhrase) throws

    func getPassPhrases(for email: String) throws -> [PassPhrase]
}

// MARK: - PassPhraseService
protocol PassPhraseServiceType {
    func getPassPhrases(for email: String) throws -> [PassPhrase]
    func savePassPhrase(with passPhrase: PassPhrase, storageMethod: PassPhraseStorageMethod) throws
    func updatePassPhrase(with passPhrase: PassPhrase, storageMethod: PassPhraseStorageMethod) throws
    func savePassPhrasesInMemory(_ passPhrase: String, for privateKeys: [Keypair]) throws
}

final class PassPhraseService: PassPhraseServiceType {
    private lazy var logger = Logger.nested(Self.self)

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
            let storedPassPhrases = try encryptedStorage.getPassPhrases(for: "")
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
        try encryptedStorage.getPassPhrases(for: email) + inMemoryStorage.getPassPhrases(for: email)
    }

    func savePassPhrasesInMemory(_ passPhrase: String, for privateKeys: [Keypair]) throws {
        for privateKey in privateKeys {
            let pp = PassPhrase(value: passPhrase, fingerprintsOfAssociatedKey: privateKey.allFingerprints)
            try savePassPhrase(with: pp, storageMethod: .memory)
        }
    }
}
