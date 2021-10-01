//
//  LocalPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

final class InMemoryPassPhraseStorage: PassPhraseStorageType {
    private lazy var logger = Logger.nested(Self.self)

    let timeoutInSeconds: Int
    let calendar = Calendar.current
    let passPhraseProvider: InMemoryPassPhraseProviderType

    init(
        passPhraseProvider: InMemoryPassPhraseProviderType = InMemoryPassPhraseProvider.shared,
        timeoutInSeconds: Int = 4*60*60 // 4 hours
    ) {
        self.passPhraseProvider = passPhraseProvider
        self.timeoutInSeconds = timeoutInSeconds
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
        passPhraseProvider.removePassPhrases(with: passPhrase)
    }

    func getPassPhrases() -> [PassPhrase] {
        passPhraseProvider.passPhrases
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

                let isPassPhraseValid = timePassed < timeoutInSeconds

                if isPassPhraseValid {
                    return passPhrase
                } else {
                    return nil
                }
            }
    }
}

// MARK: - Convenience

protocol InMemoryPassPhraseProviderType {
    var passPhrases: Set<PassPhrase> { get }
    func save(passPhrase: PassPhrase)
    func removePassPhrases(with objects: PassPhrase)
}

/// - Warning: - should be shared instance
final class InMemoryPassPhraseProvider: InMemoryPassPhraseProviderType {
    static let shared: InMemoryPassPhraseProvider = InMemoryPassPhraseProvider()

    private(set) var passPhrases: Set<PassPhrase> = []

    private init() {
    }

    func save(passPhrase: PassPhrase) {
        passPhrases.insert(passPhrase)
    }

    func removePassPhrases(with objects: PassPhrase) {
        if passPhrases.contains(objects) {
            passPhrases.remove(objects)
        }
    }
}
