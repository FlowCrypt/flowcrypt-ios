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
    let date: Date?

    init(value: String, longid: String, date: Date? = nil) {
        self.value = value
        self.longid = longid
        self.date = date
    }

    func withUpdatedDate() -> PassPhrase {
        PassPhrase(value: self.value, longid: self.longid, date: Date())
    }

    static func == (lhs: PassPhrase, rhs: PassPhrase) -> Bool {
        lhs.longid == rhs.longid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(longid)
    }
}

// MARK: - Pass Phrase Storage
protocol PassPhraseStorageType {
    func save(passPhrase: PassPhrase)
    func update(passPhrase: PassPhrase)
    func remove(passPhrase: PassPhrase)

    func getPassPhrases() -> [PassPhrase]
}

// MARK: - PassPhraseService
protocol PassPhraseServiceType {
    func getPassPhrases() -> [PassPhrase]
    func savePassPhrase(with passPhrase: PassPhrase, inStorage: Bool)
    func updatePassPhrase(with passPhrase: PassPhrase, inStorage: Bool)
}

final class PassPhraseService: PassPhraseServiceType {
    private lazy var logger = Logger.nested(Self.self)

    let currentUserEmail: String?
    let encryptedStorage: PassPhraseStorageType
    let inMemoryStorage: PassPhraseStorageType

    init(
        encryptedStorage: PassPhraseStorageType = EncryptedStorage(),
        localStorage: PassPhraseStorageType = InMemoryPassPhraseStorage(),
        emailProvider: EmailProviderType = DataService.shared
    ) {
        self.encryptedStorage = encryptedStorage
        self.inMemoryStorage = localStorage
        self.currentUserEmail = emailProvider.email
    }

    func savePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if inStorage {
            logger.logInfo("Save to storage \(passPhrase.longid)")
            encryptedStorage.save(passPhrase: passPhrase)
        } else {
            logger.logInfo("Save in memory \(passPhrase.longid)")

            inMemoryStorage.save(passPhrase: passPhrase)

            let alreadySaved = encryptedStorage.getPassPhrases()

            if alreadySaved.contains(where: { $0.longid == passPhrase.longid }) {
                encryptedStorage.remove(passPhrase: passPhrase)
            }
        }
    }

    func updatePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if inStorage {
            encryptedStorage.update(passPhrase: passPhrase)
        } else {
            inMemoryStorage.save(passPhrase: passPhrase)
        }
    }

    func getPassPhrases() -> [PassPhrase] {
        encryptedStorage.getPassPhrases() + inMemoryStorage.getPassPhrases()
    }
}
