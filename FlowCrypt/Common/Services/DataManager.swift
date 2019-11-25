//
//  DataManager.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol DataManagerType {
    var email: String? { get }
    var currentUser: User? { get set }
    var currentToken: String? { get set }
    var isLogedIn: Bool { get }
}

final class DataManager: DataManagerType {
    var isLogedIn: Bool {
        currentUser != nil && currentToken != nil
    }

    var email: String? {
        currentUser?.email
    }

    var currentUser: User? {
        get {
            localStorage.currentUser()
        }
        set {
            localStorage.saveCurrent(user: newValue)
            encryptedStorage.ecnryptFor(email: newValue?.email)
        }
    }

    var currentToken: String? {
        get { encryptedStorage.currentToken() }
        set { encryptedStorage.saveToken(with: newValue) }
    }

    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private var localStorage: LocalStorageType & LogOutHandler

    init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
    }
}

extension DataManager: LogOutHandler {
    func logOut() {
        [localStorage, encryptedStorage].map { $0 as LogOutHandler }.forEach {
            $0.logOut()
        }
    }
}
