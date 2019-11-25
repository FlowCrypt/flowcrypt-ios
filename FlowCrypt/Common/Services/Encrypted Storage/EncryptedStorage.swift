//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

protocol EncryptedStorageType {
    func ecnryptFor(email: String?)

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func saveToken(with string: String?)

    func currentToken() -> String?
    func publicKey() -> String?
    func keys() -> Results<KeyInfo>?
}

final class EncryptedStorage: EncryptedStorageType {
    let keychainHelper: KeyChainServiceType
    var email: String?
    
    init(keychainHelper: KeyChainServiceType = KeyChainService()) {
        self.keychainHelper = KeyChainService()
    }

    private var storage: Realm? {
        guard let email = email else { return nil }

        do {
            let config = Realm.Configuration(encryptionKey: self.keychainHelper.getEncryptedKey(for: email))
            let realm = try Realm(configuration: config)
            print(realm)
        } catch let error as NSError {
            fatalError("Error opening realm: \(error)")
        }
        let realm = try? Realm(configuration: Realm.Configuration(encryptionKey: self.keychainHelper.getEncryptedKey(for: email)))
        return realm
    }

    func ecnryptFor(email: String?) {
        // clear all data
        logOut()

        guard let email = email, case .success = keychainHelper.saveEncryptedKey(for: email) else {
            logOut()
            return
        }

        self.email = email
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        try! storage?.write {
            for k in keyDetails {
                storage?.add(try! KeyInfo(k, passphrase: passPhrase, source: source))
            }
        }
    }

    func publicKey() -> String? {
        return storage?.objects(KeyInfo.self)
            .map { $0.public }
            .first 
    }

    func keys() -> Results<KeyInfo>? {
        storage?.objects(KeyInfo.self)
    }

    func saveToken(with string: String?) {
        guard let token = string else {
            logOut()
            return
        }
        try? storage?.write {
            self.storage?.add(Token(value: token))
        }
    }

    func currentToken() -> String? {
        storage?.objects(Token.self).first?.value
    }
}

extension EncryptedStorage: LogOutHandler {
    func logOut() {
        try? storage?.write {
            storage?.deleteAll()
        }
        try? Realm().write {
            try? Realm().deleteAll()
        }
    }
}



