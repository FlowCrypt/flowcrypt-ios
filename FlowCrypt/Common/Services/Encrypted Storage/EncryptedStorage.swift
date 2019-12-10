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
    func encrypt()

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func saveToken(with string: String?)

    func currentToken() -> String?
    func publicKey() -> String?
    func keys() -> Results<KeyInfo>?
}

final class EncryptedStorage: EncryptedStorageType {
    let keychainService: KeyChainServiceType
    private var canHaveAccessToStorage: Bool { accessCheck() }
    private let accessCheck: () -> (Bool)

    init(keychainHelper: KeyChainServiceType = KeyChainService(), accessCheck: @escaping () -> (Bool)) {
        self.keychainService = KeyChainService()
        self.accessCheck = accessCheck
    }

    private var encryptedConfiguration: Realm.Configuration? {
        guard canHaveAccessToStorage else { return nil }
        let configuration = Realm.Configuration(encryptionKey: self.keychainService.getStorageEncryptionKey())
        return configuration
    }

    var storage: Realm? {
        do {
            guard let configuration = self.encryptedConfiguration else { return nil }
            let realm = try Realm(configuration: configuration)
            return realm
        } catch let error {
            assertionFailure("Check Realm")
            return nil
        }
    }

    func encrypt() {
        guard canHaveAccessToStorage else { return }
        let status = keychainService.generateAndSaveStorageEncryptionKey()
        
        switch status {
        case .success:
            break
        case .noData:
            assertionFailure("Keychain could not save generated key")
            logOut()
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
            self.storage?.add(EmailAccessToken(value: token))
        }
    }

    func currentToken() -> String? {
        storage?.objects(EmailAccessToken.self).first?.value
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



