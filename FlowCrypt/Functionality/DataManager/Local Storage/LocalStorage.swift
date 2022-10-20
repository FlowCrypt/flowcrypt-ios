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

extension LocalStorage {
    func cleanup() {
        for key in Constants.allCases.map(\.rawValue) {
            storage.removeObject(forKey: key)
        }
    }
}
