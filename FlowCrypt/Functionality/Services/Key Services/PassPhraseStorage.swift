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

final class PassPhraseStorage: PassPhraseStorageType {
    private enum Constants {
        static let passPhraseIndex = "passPhraseIndex"
    }
    private lazy var logger = Logger.nested(Self.self)

    let currentUserEmail: () -> (String?)
    let storage: EncryptedStorage
    let localStorage: UserDefaults
    let timeout: Int
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    private var subscription: NSObjectProtocol?

    init(
        storage: EncryptedStorage = EncryptedStorage(),
        localStorage: UserDefaults = .standard,
        timeout: Int = 4,
        currentUserEmail: @autoclosure @escaping () -> (String?) = DataService.shared.email
    ) {
        self.storage = storage
        self.localStorage = localStorage
        self.timeout = timeout
        self.currentUserEmail = currentUserEmail
    }

    deinit {
        if let subscription = subscription {
            NotificationCenter.default.removeObserver(subscription)
        }
    }

    private func subscribeToTerminateNotification() {
        subscription = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logger.logInfo("App is about to terminate")
            self.localStorage.removeObject(forKey: Constants.passPhraseIndex)
        }
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

        getAllLocallySavedPassPhrases()
            .forEach { localPassPhrases in
                guard calendar.component(.hour, from: localPassPhrases.date) < timeout else {
                    self.logger.logInfo("pass phrase is invalid \(localPassPhrases.passPhrase.longid)")
                    invalidPassPhrases.append(localPassPhrases)
                    return
                }
                validPassPhrases.append(localPassPhrases.passPhrase)
            }
        removeInvalidPassPhrases(with: invalidPassPhrases)

        logger.logInfo("validPassPhrases \(validPassPhrases.count)")
        return dbPassPhrases + validPassPhrases
    }

    func saveLocally(passPhrase: String) {
        guard let email = currentUserEmail() else {
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
        var temporaryPassPhrases = getAllLocallySavedPassPhrases()
        // update with new pass
        temporaryPassPhrases.append(LocalPassPhrase(passPhrase: passPhrase, date: Date()))
        // save to storage
        encodeAndSave(passPhrases: temporaryPassPhrases)
    }

    private func removeInvalidPassPhrases(with objects: [LocalPassPhrase]) {
        var temporaryPassPhrases = getAllLocallySavedPassPhrases()

        objects.forEach { localPassPhrases in
            temporaryPassPhrases.removeAll(where: { $0.date == localPassPhrases.date })
        }

        encodeAndSave(passPhrases: temporaryPassPhrases)
    }

    private func getAllLocallySavedPassPhrases() -> [LocalPassPhrase] {
        guard let data = localStorage.data(forKey: Constants.passPhraseIndex),
              let result = try? decoder.decode([LocalPassPhrase].self, from: data) else {
            return []
        }

        return result
    }

    private func encodeAndSave(passPhrases: [LocalPassPhrase]) {
        let objectsToSave = try? encoder.encode(passPhrases)
        localStorage.set(objectsToSave, forKey: Constants.passPhraseIndex)
    }
}

private struct LocalPassPhrase: Codable {
    let passPhrase: PassPhrase
    let date: Date
}
