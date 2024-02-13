//
//  InMemoryPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

final class InMemoryPassPhraseStorage: PassPhraseStorageType {
    private lazy var logger = Logger.nested(Self.self)

    let DEFAULT_PASSPHRASE_TIMEOUT_IN_SECONDS = 4 * 60 * 60 // 4 hours
    let calendar = Calendar.current
    let passPhraseProvider: InMemoryPassPhraseProviderType

    init(
        passPhraseProvider: InMemoryPassPhraseProviderType = InMemoryPassPhraseProvider.shared
    ) {
        self.passPhraseProvider = passPhraseProvider
    }

    func save(passPhrase: PassPhrase) {
        let passPhraseToSave = passPhrase.withUpdatedDate()
        passPhraseProvider.save(passPhrase: passPhraseToSave)
    }

    func update(passPhrase: PassPhrase) {
        let passPhraseToSave = passPhrase.withUpdatedDate()
        passPhraseProvider.save(passPhrase: passPhraseToSave)
    }

    func remove(passPhrase: PassPhrase) {
        passPhraseProvider.remove(passPhrases: [passPhrase])
    }

    func getPassPhrases(for email: String, expirationInSeconds: Int?) throws -> [PassPhrase] {
        return passPhraseProvider.passPhrases
            .compactMap { passPhrase -> PassPhrase? in
                guard let dateToCompare = passPhrase.date else {
                    logger.logError("Date should not be nil")
                    return nil
                }

                let components = calendar.dateComponents(
                    [.second],
                    from: dateToCompare,
                    to: Date()
                )

                let timePassed = components.second ?? 0
                let isPassPhraseValid = timePassed < (expirationInSeconds ?? DEFAULT_PASSPHRASE_TIMEOUT_IN_SECONDS)

                return isPassPhraseValid ? passPhrase : nil
            }
            .filter { $0.email == email }
    }

    func removePassPhrases(for email: String) {
        let userPassPhrases = passPhraseProvider.passPhrases.filter { $0.email == email }
        passPhraseProvider.remove(passPhrases: userPassPhrases)
    }
}

// MARK: - Convenience

protocol InMemoryPassPhraseProviderType {
    var passPhrases: Set<PassPhrase> { get }
    func save(passPhrase: PassPhrase)
    func remove(passPhrases: Set<PassPhrase>)
}

/// - Warning: - should be shared instance
final class InMemoryPassPhraseProvider: InMemoryPassPhraseProviderType {
    static let shared = InMemoryPassPhraseProvider()

    private(set) var passPhrases: Set<PassPhrase> = []

    private init() {}

    func save(passPhrase: PassPhrase) {
        passPhrases.update(with: passPhrase)
    }

    func remove(passPhrases passPhrasesToDelete: Set<PassPhrase>) {
        for passPhraseToDelete in passPhrasesToDelete {
            passPhrases.remove(passPhraseToDelete)
        }
    }
}
