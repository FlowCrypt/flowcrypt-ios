//
//  LocalStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol LocalStorageType {
    var storage: UserDefaults { get }

    var trashFolderPath: String? { get }
    func saveTrashFolder(path: String)
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
    func logOutUser(email: String) {
        Constants.allCases
            .compactMap { $0.rawValue }
            .forEach {
                storage.removeObject(forKey: $0)
            }
    }
}
