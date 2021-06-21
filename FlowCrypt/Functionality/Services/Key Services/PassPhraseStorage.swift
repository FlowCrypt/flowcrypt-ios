//
//  PassPhraseStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol PassPhraseStorageType {
    func getPassPhrases() -> [PassPhrase]
    func savePassPhrase(with passPhrase: PassPhrase, inStorage: Bool)
    func updatePassPhrase(with passPhrase: PassPhrase, inStorage: Bool)
}

protocol EmailProviderType {
    var email: String? { get }
}

final class PassPhraseStorage: PassPhraseStorageType {
    private lazy var logger = Logger.nested(Self.self)

    let currentUserEmail: String?
    let encryptedStorage: EncryptedPassPhraseStorage
    let inMemoryStorage: InMemoryPassPhraseStorageType
    let timeoutInSeconds: Int

    init(
        storage: EncryptedPassPhraseStorage,
        localStorage: InMemoryPassPhraseStorageType = InMemoryPassPhraseStorage.shared,
        timeoutInSeconds: Int = 4*60*60, // 4 hours
        emailProvider: EmailProviderType,
        isHours: Bool = true
    ) {
        self.encryptedStorage = storage
        self.inMemoryStorage = localStorage
        self.timeoutInSeconds = timeoutInSeconds
        self.currentUserEmail = emailProvider.email
    }

    func savePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if inStorage {
            logger.logInfo("Save to storage \(passPhrase.longid)")
            encryptedStorage.addPassPhrase(object: PassPhraseObject(passPhrase))
        } else {
            logger.logInfo("Save locally \(passPhrase.longid)")

            let inMemoryPassPhrase = InMemoryPassPhrase(passPhrase: passPhrase, date: Date())
            inMemoryStorage.save(passPhrase: inMemoryPassPhrase)

            let alreadySaved = encryptedStorage.getPassPhrases()

            if alreadySaved.contains(where: { $0.longid == passPhrase.longid }) {
                encryptedStorage.removePassPhrase(object: PassPhraseObject(passPhrase))
            }
        }
    }

    func updatePassPhrase(with passPhrase: PassPhrase, inStorage: Bool) {
        if inStorage {
            encryptedStorage.updatePassPhrase(object: PassPhraseObject(passPhrase))
        } else {
            let updated = InMemoryPassPhrase(passPhrase: passPhrase, date: Date())
            inMemoryStorage.save(passPhrase: updated)
        }
    }

    func getPassPhrases() -> [PassPhrase] {
        let dbPassPhrases = encryptedStorage.getPassPhrases()
            .map(PassPhrase.init)

        logger.logInfo("dbPassPhrases \(dbPassPhrases.count)")

        let calendar = Calendar.current

        var validPassPhrases: [PassPhrase] = []
        var invalidPassPhrases: [InMemoryPassPhrase] = []

        inMemoryStorage.passPhrases
            .forEach { localPassPhrases in
                let components = calendar.dateComponents(
                    [.second],
                    from: localPassPhrases.date,
                    to: Date()
                )

                let timePassed = components.second ?? 0

                let isPassPhraseValid = timePassed < timeoutInSeconds

                if isPassPhraseValid {
                    validPassPhrases.append(localPassPhrases.passPhrase)
                } else {
                    invalidPassPhrases.append(localPassPhrases)
                }

                let message = "pass phrase is \(isPassPhraseValid ? "valid" : "invalid") \(localPassPhrases.passPhrase.longid)"
                self.logger.logInfo(message)
            }

        inMemoryStorage.removePassPhrases(with: invalidPassPhrases)

        logger.logInfo("validPassPhrases \(validPassPhrases.count)")
        return dbPassPhrases + validPassPhrases
    }
}
