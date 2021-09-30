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

    init(storage: UserDefaults = .standard) {
        self.storage = storage
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
        // For now we store only trash folder path in user defaults
        // see no reason to add logic for removing data for a concrete user
        cleanup()
    }

    func cleanup() {
        Constants.allCases
            .map(\.rawValue)
            .forEach {
                storage.removeObject(forKey: $0)
            }
    }
}
