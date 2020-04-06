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
    func saveCurrentUser(user: User?)
    func currentUser() -> User?
}

struct LocalStorage: LocalStorageType {

    private enum Constants: String, CaseIterable {
        case indexCurrentUser = "keyCurrentUser"
    }

    let storage: UserDefaults

    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }
}

extension LocalStorage {
    func saveCurrentUser(user: User?) {
        guard let user = user else {
            storage.set(nil, forKey: Constants.indexCurrentUser.rawValue)
            return
        }
        do {
            let encodedData = try PropertyListEncoder().encode(user)
            storage.set(encodedData, forKey: Constants.indexCurrentUser.rawValue)
        } catch let error {
            fatalError("Could not save user: \(error)")
        }
    }

    func currentUser() -> User? {
        guard let data = storage.object(forKey: Constants.indexCurrentUser.rawValue) as? Data else { return nil }
        return try? PropertyListDecoder().decode(User.self, from: data)
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
