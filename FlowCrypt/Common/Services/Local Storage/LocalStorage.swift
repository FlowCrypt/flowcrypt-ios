//
//  LocalStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol LocalStorageType {
    func saveCurrentUser(user: User?)
    func currentUser() -> User?
}

struct LocalStorage: LocalStorageType {

    private enum Constants: String, CaseIterable {
        case indexCurrentUser = "keyCurrentUser"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}

extension LocalStorage {
    func saveCurrentUser(user: User?) {
        guard let user = user else {
            logOut()
            return
        }
        do {
            let encodedData = try PropertyListEncoder().encode(user)
            userDefaults.set(encodedData, forKey: Constants.indexCurrentUser.rawValue)
        } catch let error {
            fatalError("Could not save user: \(error)")
        }
    }

    func currentUser() -> User? {
        guard let data = userDefaults.object(forKey: Constants.indexCurrentUser.rawValue) as? Data else { return nil }
        return try? PropertyListDecoder().decode(User.self, from: data)
    }
}

extension LocalStorage: LogOutHandler {
    func logOut() {
        Constants.allCases
            .compactMap { $0.rawValue }
            .forEach {
                userDefaults.removeObject(forKey: $0)
            }
    }
}
