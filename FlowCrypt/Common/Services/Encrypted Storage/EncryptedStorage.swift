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
        let key = self.keychainService.getStorageEncryptionKey()
        return Realm.Configuration(encryptionKey: key)
    }

    var storage: Realm? {
        guard let configuration = self.encryptedConfiguration else { return nil }
        do {
            let realm = try Realm(configuration: configuration)
            return realm
        } catch let error {
            // destroyEncryptedStorage()
            // log()
            // return nil
            fatalError("Check Realm: \(error)")
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
    func logOut() { // log out is not clear - should be called DestroyEncryptedStorage
        destroyEncryptedStorage()
    }

    private func destroyEncryptedStorage() {
        do {
            if let oldPlainConfiguration = Realm.Configuration.defaultConfiguration.fileURL {
                try FileManager.default.removeItem(at: oldPlainConfiguration)
            }
        } catch CocoaError.fileNoSuchFile {
        } catch let error {
            fatalError("Could not delete oldPlainConfiguration: \(error)")
        }
        do {
            if let url = encryptedConfiguration?.fileURL {
                try FileManager.default.removeItem(at: url)
            }
        } catch CocoaError.fileNoSuchFile {
        } catch let error {
            fatalError("Could not delete encryptedConfiguration: \(error)")
        }
    }
}



