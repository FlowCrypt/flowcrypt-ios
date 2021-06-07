//
//  LocalPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol LocalPassPhraseStorageType {
    func getAllLocallySavedPassPhrases() -> [LocalPassPhrase]
    func encodeAndSave(passPhrases: [LocalPassPhrase])
}

struct LocalPassPhrase: Codable {
    let passPhrase: PassPhrase
    let date: Date
}

final class LocalPassPhraseStorage: LocalPassPhraseStorageType {
    private enum Constants {
        static let passPhraseIndex = "passPhraseIndex"
    }
    private lazy var logger = Logger.nested(Self.self)

    let localStorage: UserDefaults
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    private var subscription: NSObjectProtocol?

    init(localStorage: UserDefaults = .standard) {
        self.localStorage = localStorage
        subscribeToTerminateNotification()
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

    func getAllLocallySavedPassPhrases() -> [LocalPassPhrase] {
        guard let data = localStorage.data(forKey: Constants.passPhraseIndex),
              let result = try? decoder.decode([LocalPassPhrase].self, from: data) else {
            return []
        }

        return result
    }

    func encodeAndSave(passPhrases: [LocalPassPhrase]) {
        let objectsToSave = try? encoder.encode(passPhrases)
        localStorage.set(objectsToSave, forKey: Constants.passPhraseIndex)
    }
}
