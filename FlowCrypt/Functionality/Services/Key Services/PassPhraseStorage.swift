//
//  PassPhraseStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

// MARK: - Data Object
struct PassPhrase: Codable, Hashable, Equatable {
    let value: String
    let longid: String

    init(value: String, longid: String) {
        self.value = value
        self.longid = longid
    }
}

// MARK: - Encrypted
protocol EncryptedPassPhraseStorage {
    func save(passPhrase: PassPhraseObject)
    func update(passPhrase: PassPhraseObject)
    func remove(passPhrase: PassPhraseObject)

    func getPassPhrases() -> [PassPhraseObject]
}

// MARK: - In memory
protocol InMemoryPassPhraseStorageType {
    func save(passPhrase: InMemoryPassPhrase)
    func update(passPhrase: InMemoryPassPhrase)
    func remove(passPhrase: InMemoryPassPhrase)

    func getPassPhrases() -> [InMemoryPassPhrase]
}

// MARK: - PassPhrase Service
protocol PassPhraseStorageType {
    func getPassPhrases() -> [PassPhrase]
    func savePassPhrase(with passPhrase: PassPhrase, inStorage: Bool)
    func updatePassPhrase(with passPhrase: PassPhrase, inStorage: Bool)
}

final class PassPhraseStorage: PassPhraseStorageType {
    private lazy var logger = Logger.nested(Self.self)

    let currentUserEmail: String?
    let encryptedStorage: EncryptedPassPhraseStorage
    let inMemoryStorage: InMemoryPassPhraseStorageType

    init(
        storage: EncryptedPassPhraseStorage = EncryptedStorage(),
        localStorage: InMemoryPassPhraseStorageType = InMemoryPassPhraseStorage(),
        emailProvider: EmailProviderType
    ) {
        self.encryptedStorage = storage
        self.inMemoryStorage = localStorage
        self.currentUserEmail = emailProvider.email
    }

    func savePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if inStorage {
            logger.logInfo("Save to storage \(passPhrase.longid)")
            encryptedStorage.save(passPhrase: PassPhraseObject(passPhrase))
        } else {
            logger.logInfo("Save locally \(passPhrase.longid)")

            let inMemoryPassPhrase = InMemoryPassPhrase(passPhrase: passPhrase, date: Date())
            inMemoryStorage.save(passPhrase: inMemoryPassPhrase)

            let alreadySaved = encryptedStorage.getPassPhrases()

            if alreadySaved.contains(where: { $0.longid == passPhrase.longid }) {
                encryptedStorage.remove(passPhrase: PassPhraseObject(passPhrase))
            }
        }
    }

    func updatePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if inStorage {
            encryptedStorage.update(passPhrase: PassPhraseObject(passPhrase))
        } else {
            let updated = InMemoryPassPhrase(passPhrase: passPhrase, date: Date())
            inMemoryStorage.save(passPhrase: updated)
        }
    }

    func getPassPhrases() -> [PassPhrase] {
        let dbPassPhrases = encryptedStorage.getPassPhrases()
            .map(PassPhrase.init)

        let inMemoryPassPhrases = inMemoryStorage.getPassPhrases()
            .map(PassPhrase.init)

        logger.logInfo("dbPassPhrases \(dbPassPhrases.count)")
        logger.logInfo("inMemoryPassPhrases \(inMemoryPassPhrases.count)")

        return dbPassPhrases + inMemoryPassPhrases
    }
}
