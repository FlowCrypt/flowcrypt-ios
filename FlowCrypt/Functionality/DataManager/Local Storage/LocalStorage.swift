//
//  LocalStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol LocalStorageType {
    var storage: UserDefaults { get }

    var trashFolderPath: String? { get }
    func saveTrashFolder(path: String)

    func cleanup()
}

struct LocalStorage: LocalStorageType {
    private enum Constants: String, CaseIterable {
        case indexTrashFolder
    }

    let storage: UserDefaults
    let passPhraseStorage: PassPhraseStorageType & LogOutHandler

    init(storage: UserDefaults = .standard,
         passPhraseStorage: PassPhraseStorageType & LogOutHandler = InMemoryPassPhraseStorage()) {
        self.storage = storage
        self.passPhraseStorage = passPhraseStorage
    }
}

extension LocalStorage {
    var trashFolderPath: String? {
        storage.string(forKey: Constants.indexTrashFolder.rawValue)
    }
    func saveTrashFolder(path: String) {
        storage.set(path, forKey: Constants.indexTrashFolder.rawValue)
    }
}

extension LocalStorage: LogOutHandler {
    func logOutUser(email: String) throws {
        try passPhraseStorage.logOutUser(email: email)
        // For now we store only trash folder path in user defaults
        // see no reason to add logic for removing data for a concrete user
        cleanup()
    }

    func cleanup() {
        for key in Constants.allCases.map(\.rawValue) {
            storage.removeObject(forKey: key)
        }
    }
}
