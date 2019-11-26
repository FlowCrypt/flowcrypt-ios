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
    private var email: String? { emailGetter() }
    private let emailGetter: () -> (String?)

    init(keychainHelper: KeyChainServiceType = KeyChainService(), email: @escaping () -> (String?)) {
        self.keychainHelper = KeyChainService()
        self.emailGetter = email
    }

    private var encryptedConfiguration: Realm.Configuration? {
        guard let email = email else { return nil }
        let configuration = Realm.Configuration(encryptionKey: self.keychainHelper.getEncryptedKey(for: email))
        return configuration
    }

    private var storage: Realm? {
        do {
            guard let configuration = self.encryptedConfiguration else { return nil }
            let realm = try Realm(configuration: configuration)
            return realm
        } catch let error {
            print("^^ \(error)")
            return nil
        }
    }

    func ecnryptFor(email: String?) {
        // clear all data
        logOut()

        guard let email = email, case .success = keychainHelper.saveEncryptedKey(for: email) else {
            logOut()
            return
        }
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
        do {
            if let oldConfigurationURL = Realm.Configuration.defaultConfiguration.fileURL {
                try FileManager.default.removeItem(at: oldConfigurationURL)
            }
            if let url = encryptedConfiguration?.fileURL {
                try FileManager.default.removeItem(at: url)
            }
        } catch let error {
            print("^^ \(error)")
        }
    }
}



