//
//  LocalPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

// MARK: - Data Object
struct InMemoryPassPhrase: Codable, Hashable, Equatable {
    let passPhrase: PassPhrase
    let date: Date

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.passPhrase.longid == rhs.passPhrase.longid
    }
}

// MARK: - Storage
final class InMemoryPassPhraseStorage: InMemoryPassPhraseStorageType {
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

    func save(passPhrase: InMemoryPassPhrase) {
        passPhraseProvider.save(passPhrase: passPhrase)
    }

    func update(passPhrase: InMemoryPassPhrase) {
        passPhraseProvider.save(passPhrase: passPhrase)
    }

    func remove(passPhrase: InMemoryPassPhrase) {
        passPhraseProvider.removePassPhrases(with: passPhrase)
    }

    func getPassPhrases() -> [InMemoryPassPhrase] {
        passPhraseProvider.passPhrases
            .compactMap { passPhrase -> InMemoryPassPhrase? in
                let components = calendar.dateComponents(
                    [.second],
                    from: passPhrase.date,
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
    var passPhrases: Set<InMemoryPassPhrase> { get }
    func save(passPhrase: InMemoryPassPhrase)
    func removePassPhrases(with objects: InMemoryPassPhrase)
}

/// - Warning: - should be shared instance
final class InMemoryPassPhraseProvider: InMemoryPassPhraseProviderType {
    static let shared: InMemoryPassPhraseProvider = InMemoryPassPhraseProvider()

    private(set) var passPhrases: Set<InMemoryPassPhrase> = []

    private init() {
    }

    func save(passPhrase: InMemoryPassPhrase) {
        passPhrases.insert(passPhrase)
    }

    func removePassPhrases(with objects: InMemoryPassPhrase) {
        if passPhrases.contains(objects) {
            passPhrases.remove(objects)
        }
    }
}

extension PassPhrase {
    init(object: InMemoryPassPhrase) {
        self.init(value: object.passPhrase.value, longid: object.passPhrase.longid)
    }
}
