//
//  DataManager.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct DataManager {
    // TODO: - safe in keychain
    static var shared = DataManager()

    private enum Constants {
        static let userKey = "keyCurrentUser"
        static let tokenKey = "keyCurrentToken"
    }

    var a = 0

    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func saveToken(with string: String) {
        userDefaults.set(string, forKey: Constants.tokenKey)
    }

    func currentToken() -> String? {
//        if a == 0 { 
//            return "asfff"
//        }
        return userDefaults.string(forKey: Constants.tokenKey)
    }

    func saveCurrent(user: User) -> Bool {
        do {
            let encodedData = try PropertyListEncoder().encode(user)
            userDefaults.set(encodedData, forKey: Constants.userKey)
            return true
        } catch let error {
            print(error)
            return false
        }
    }

    func currentUser() -> User? {
        return try? PropertyListDecoder().decode(
            User.self,
            from: userDefaults.object(forKey: Constants.userKey) as! Data
        )
    }

    func logOut() {
        [Constants.tokenKey, Constants.userKey]
            .forEach {
                userDefaults.removeObject(forKey: $0)
        }
    }
}
