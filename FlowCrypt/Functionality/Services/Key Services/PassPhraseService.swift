//
//  PassPhraseStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

// MARK: - Data Object
struct PassPhrase: Codable, Hashable, Equatable {
    let value: String
    let fingerprints: [String]
    let date: Date?

    var primaryFingerprint: String {
        fingerprints[0]
    }

    init(value: String, fingerprints: [String], date: Date? = nil) {
        self.value = value
        self.fingerprints = fingerprints
        self.date = date
    }

    func withUpdatedDate() -> PassPhrase {
        PassPhrase(value: self.value, fingerprints: self.fingerprints, date: Date())
    }

    static func == (lhs: PassPhrase, rhs: PassPhrase) -> Bool {
        lhs.primaryFingerprint == rhs.primaryFingerprint
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(primaryFingerprint)
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
    let inMemoryStorage: PassPhraseStorageType

    init(
        localStorage: PassPhraseStorageType = InMemoryPassPhraseStorage(),
        emailProvider: EmailProviderType = DataService.shared
    ) {
        self.inMemoryStorage = localStorage
        self.currentUserEmail = emailProvider.email
    }

    func savePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if !inStorage {
            logger.logInfo("Save passphrase in memory")

            inMemoryStorage.save(passPhrase: passPhrase)
        }
    }

    func updatePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if !inStorage {
            inMemoryStorage.save(passPhrase: passPhrase)
        }
    }

    func getPassPhrases() -> [PassPhrase] {
        inMemoryStorage.getPassPhrases()
    }
}
