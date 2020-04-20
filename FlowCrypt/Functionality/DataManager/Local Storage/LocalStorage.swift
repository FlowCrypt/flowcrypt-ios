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

    var trashFolderPath: String? { get set }
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
        get { storage.string(forKey: Constants.indexTrashFolder.rawValue) }
        set { storage.set(newValue, forKey: Constants.indexTrashFolder.rawValue)}
    }
}

extension LocalStorage: LogOutHandler {
    func logOut() {
        Constants.allCases
            .compactMap { $0.rawValue }
            .forEach {
                storage.removeObject(forKey: $0)
            }
    }
}
