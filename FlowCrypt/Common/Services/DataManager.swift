//
//  DataManager.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol DataManagerType {
    func saveToken(with string: String)
    func currentToken() -> String?
    func saveCurrent(user: User) -> Bool
    func currentUser() -> User?
    func logOut()

    var email: String? { get }
}

struct DataManager: DataManagerType {
    static let shared = DataManager(userDefaults: UserDefaults.standard)

    var email: String? {
        currentUser()?.email
    }

    private lazy var storageService: StorageServiceType? = {
        StorageService(
               keychainHelper: Keyc
           )

    }()
    private let userDefaults: UserDefaults

    private enum Constants {
        static let userKey = "keyCurrentUser"
        // TODO: Anton - save to encrypted
        static let tokenKey = "keyCurrentToken"
    }

    private init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func saveToken(with string: String) {
        // TODO: Anton - save to encrypted
        userDefaults.set(string, forKey: Constants.tokenKey)
    }

    func currentToken() -> String? {
        // TODO: Anton - get from encrypted
        return userDefaults.string(forKey: Constants.tokenKey)
    }

    func saveCurrent(user: User) -> Bool {
        do {
            let encodedData = try PropertyListEncoder().encode(user)
            userDefaults.set(encodedData, forKey: Constants.userKey)
            return true
        } catch {
            return false
        }
    }

    func currentUser() -> User? {
        guard let data = userDefaults.object(forKey: Constants.userKey) as? Data else { return nil }
        return try? PropertyListDecoder().decode(User.self, from: data)
    }

    func logOut() {
        email.map { storageService.clear(for: $0) }

        [Constants.tokenKey, Constants.userKey]
            .forEach { userDefaults.removeObject(forKey: $0) }
    }
}
