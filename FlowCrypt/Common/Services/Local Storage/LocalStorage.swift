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
    func secureKeychainPrefix() -> String
}

struct LocalStorage: LocalStorageType {

    private enum Constants: String, CaseIterable {
        case indexCurrentUser = "indexCurrentUser"
        case indexSecureKeychainPrefix = "indexSecureKeychainPrefix"
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

    func secureKeychainPrefix() -> String {
        if let storedPrefix = userDefaults.string(forKey: Constants.indexSecureKeychainPrefix.rawValue) {
            return storedPrefix
        } else {
            guard let prefixBytes = CoreHost().getSecureRandomByteNumberArray(12) else {
                fatalError("could not get secureKeychainPrefix random bytes")
            }
            let prefix = Data(prefixBytes).base64EncodedString().replacingOccurrences(of: "[^A-Za-z0-9]+", with: "", options: [.regularExpression])
            print("LocalStorage.secureKeychainPrefix generating new: \(prefix)")
            userDefaults.set(prefix, forKey: Constants.indexSecureKeychainPrefix.rawValue)
            return prefix
        }
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
