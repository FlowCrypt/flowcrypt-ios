//
//  DataManager.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol DataManagerType {
    func startForNew(user: User?, with token: String?)
    
    var email: String? { get }
    var currentUser: User? { get }
    var currentToken: String? { get }
    var isLogedIn: Bool { get }

    func keys() -> [PrvKeyInfo]?
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func publicKey() -> String?
}

final class DataManager: DataManagerType {
    static let shared = DataManager()

    var isLogedIn: Bool {
        let isUserStored = currentUser != nil && currentToken != nil
        let hasKey = (self.encryptedStorage.keys()?.count ?? 0) > 0
        return isUserStored && hasKey
    }

    var email: String? {
        currentUser?.email
    }

    var currentUser: User? {
        get { localStorage.currentUser() }
    }
    var currentToken: String? {
        get { encryptedStorage.currentToken() }
    }

    private lazy var encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(accessCheck: { self.email != nil })
    private var localStorage: LocalStorageType & LogOutHandler

    private init(
        localStorage: LocalStorageType & LogOutHandler = LocalStorage()
    ) {
        self.localStorage = localStorage
    }

    func keys() -> [PrvKeyInfo]? {
        guard let keys = encryptedStorage.keys() else { return nil }
        return PrvKeyInfo.from(realm: keys)
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.addKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
    }

    func publicKey() -> String? {
        encryptedStorage.publicKey()
    }

    func startForNew(user: User?, with token: String?) {
        localStorage.saveCurrent(user: user)
        encryptedStorage.ecnryptFor(email: user?.email)
        encryptedStorage.saveToken(with: token)
    }
} 

extension DataManager: LogOutHandler {
    func logOut() {
        [localStorage, encryptedStorage].map { $0 as LogOutHandler }.forEach {
            $0.logOut()
        }
    }
}
