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
    func savePassPhrase(with passPhrase: PassPhrase, isLocally: Bool)
    func updatePassPhrase(with passPhrase: PassPhrase, isLocally: Bool)

    func saveLocally(passPhrase: String)
}

protocol EmailProviderType {
    var email: String? { get }
}

final class PassPhraseStorage: PassPhraseStorageType {
    private lazy var logger = Logger.nested(Self.self)

    let currentUserEmail: String?
    let storage: EncryptedPassPhraseStorage
    let localStorage: LocalPassPhraseStorageType
    let timeoutContext: (component: Calendar.Component, timeout: Int)

    /// used for tests only, otherwise seconds will be used
    let isHours: Bool

    init(
        storage: EncryptedPassPhraseStorage,
        localStorage: LocalPassPhraseStorageType = LocalPassPhraseStorage(),
        timeoutContext: (Calendar.Component, Int) = (.hour, 4),
        emailProvider: EmailProviderType,
        isHours: Bool = true
    ) {
        self.storage = storage
        self.localStorage = localStorage
        self.timeoutContext = timeoutContext
        self.currentUserEmail = emailProvider.email
        self.isHours = isHours
    }

    func savePassPhrase(with passPhrase: PassPhrase, isLocally: Bool) {
        if isLocally {
            logger.logInfo("Save locally \(passPhrase.longid)")

            saveLocally(passPhrase: passPhrase)

            let alreadySaved = storage.getPassPhrases()

            if alreadySaved.contains(where: { $0.longid == passPhrase.longid }) {
                storage.removePassPhrase(object: PassPhraseObject(passPhrase))
            }
        } else {
            logger.logInfo("Save to storage \(passPhrase.longid)")

            storage.addPassPhrase(object: PassPhraseObject(passPhrase))
        }
    }

    func updatePassPhrase(with passPhrase: PassPhrase, isLocally: Bool) {
        storage.updatePassPhrase(object: PassPhraseObject(passPhrase))
    }

    func getPassPhrases() -> [PassPhrase] {
        let dbPassPhrases = storage.getPassPhrases()
            .map(PassPhrase.init)

        logger.logInfo("dbPassPhrases \(dbPassPhrases.count)")

        let calendar = Calendar.current

        var validPassPhrases: [PassPhrase] = []
        var invalidPassPhrases: [LocalPassPhrase] = []

        localStorage.getAllLocallySavedPassPhrases()
            .forEach { localPassPhrases in
                let components = calendar.dateComponents(
                    [timeoutContext.component],
                    from: localPassPhrases.date,
                    to: Date()
                )

                let timePassed: Int
                if self.isHours {
                    timePassed = components.hour ?? 0
                } else {
                    timePassed = components.second ?? 0
                }

                let isPassPhraseValid = timePassed < timeoutContext.timeout

                if isPassPhraseValid {
                    validPassPhrases.append(localPassPhrases.passPhrase)
                } else {
                    invalidPassPhrases.append(localPassPhrases)
                }

                let message = "pass phrase is \(isPassPhraseValid ? "valid" : "invalid") \(localPassPhrases.passPhrase.longid)"
                self.logger.logInfo(message)
            }
        removeInvalidPassPhrases(with: invalidPassPhrases)

        logger.logInfo("validPassPhrases \(validPassPhrases.count)")
        return dbPassPhrases + validPassPhrases
    }

    func saveLocally(passPhrase: String) {
        guard let email = currentUserEmail else {
            return
        }

        storage.keysInfo()
            .filter {
                $0.account.contains(email)
            }
            .forEach {
                saveLocally(passPhrase: PassPhrase(value: passPhrase, longid: $0.longid))
            }
    }

    private func saveLocally(passPhrase: PassPhrase) {
        // get all saved
        var temporaryPassPhrases = localStorage.getAllLocallySavedPassPhrases()
        // update with new pass
        temporaryPassPhrases.append(LocalPassPhrase(passPhrase: passPhrase, date: Date()))
        // save to storage
        localStorage.encodeAndSave(passPhrases: temporaryPassPhrases)
    }

    private func removeInvalidPassPhrases(with objects: [LocalPassPhrase]) {
        var temporaryPassPhrases = localStorage.getAllLocallySavedPassPhrases()

        objects.forEach { localPassPhrases in
            temporaryPassPhrases.removeAll(where: { $0.date == localPassPhrases.date })
        }

        localStorage.encodeAndSave(passPhrases: temporaryPassPhrases)
    }
}
