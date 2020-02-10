//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

protocol DBMigration {
    func performMigrationIfNeeded()
}

protocol EncryptedStorageType: DBMigration {
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func saveToken(with string: String?)
    func currentToken() -> String?
    func publicKey() -> String?
    func keys() -> Results<KeyInfo>?
}

final class EncryptedStorage: EncryptedStorageType {
    enum Constants {
        static let schemaVersion: UInt64 = 2
        static let encryptedDBName = "encr.realm"
    }

    let keychainService: KeyChainServiceType
    private var canHaveAccessToStorage: Bool { accessCheck() }
    private let accessCheck: () -> (Bool)
    private let fileManager: FileManager

    init(
        fileManager: FileManager = .default,
        keychainHelper: KeyChainServiceType = KeyChainService(),
        accessCheck: @escaping () -> (Bool)
    ) {
        self.fileManager = fileManager
        self.keychainService = KeyChainService()
        self.accessCheck = accessCheck
    }

    private var realmKey: Data {
        keychainService.getStorageEncryptionKey()
    }

    private var encryptedConfiguration: Realm.Configuration? {
        // guard canHaveAccessToStorage else { return nil }


//        let realmDefault = Realm.Configuration.defaultConfiguration
//        let realmWithKey = Realm.Configuration(encryptionKey: realmKey)
//        let realmWithPath = Realm.Configuration(
//            fileURL: URL(fileURLWithPath: isEncryptedRealmExsist().path ?? ""),
//            encryptionKey: realmKey,
//            schemaVersion: Constants.schemaVersion,
//            migrationBlock: { migration, oldSchemaVersion in
//                log("oldSchemaVersion \(oldSchemaVersion)")
//                log("Performing migration \(migration)")
//            })
//
//        print("^^ realmDefault \(realmDefault)")
//        print("^^ realmWithKey \(realmWithKey)")
//        print("^^ realmWithPath \(realmWithPath)")

        let isExsist = isEncryptedRealmExsist().0
        if !isExsist {
            return Realm.Configuration(encryptionKey: realmKey)
        } else {
            guard let path = isEncryptedRealmExsist().path else {
                fatalError("Path for encrypted Realm not exist")
            }
            return Realm.Configuration(
                fileURL: URL(fileURLWithPath: path),
                encryptionKey: realmKey,
                schemaVersion: Constants.schemaVersion,
                migrationBlock: { migration, oldSchemaVersion in
                    log("oldSchemaVersion \(oldSchemaVersion)")
                    log("Performing migration \(migration)")
                }
            )
        }

    }

    private var storage: Realm? {
        guard let configuration = self.encryptedConfiguration else { return nil }
        do {
            return try Realm(configuration: configuration)
        } catch let error {
//             destroyEncryptedStorage() - todo - give user option to wipe, don't do it automatically
//             return nil
            fatalError("failed to initiate realm: \(error)")
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
        storage?.objects(KeyInfo.self)
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
        [Realm.Configuration.defaultConfiguration.fileURL, encryptedConfiguration?.fileURL]
            .compactMap { $0 }


        do {
            if let oldPlainConfiguration = Realm.Configuration.defaultConfiguration.fileURL {
                try fileManager.removeItem(at: oldPlainConfiguration)
            }
        } catch CocoaError.fileNoSuchFile {
        } catch let error {
            fatalError("Could not delete oldPlainConfiguration: \(error)")
        }

        do {
            if let url = encryptedConfiguration?.fileURL {
                try fileManager.removeItem(at: url)
            }
        } catch CocoaError.fileNoSuchFile {
        } catch let error {
            fatalError("Could not delete encryptedConfiguration: \(error)")
        }
    }
}

extension EncryptedStorage {
    func performMigrationIfNeeded() {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            assertionFailure("No path direction for documentDirectory")
            return
        }

        let unencryptedRealmPath = documentDirectory + "/default.realm"
        let encryptedPath = documentDirectory + "/" + Constants.encryptedDBName

        let isUnencryptedRealmExsist = fileManager.fileExists(atPath: unencryptedRealmPath)
        let isEncryptedRealmExsist = fileManager.fileExists(atPath: encryptedPath)

        guard isUnencryptedRealmExsist && !isEncryptedRealmExsist else {
            debugPrint("Migration not needed")
            return
        }

        debugPrint("Perform migration")

        var oldRealm: Realm? = nil
        if let defaultRealm = try? Realm.init(configuration: Realm.Configuration.defaultConfiguration) {
            print("^^ default config \(defaultRealm)")
            oldRealm = defaultRealm
        }
        if let previouslyEncrypted = try? Realm(configuration: Realm.Configuration(encryptionKey: realmKey)) {
            print("^^ previouslyEncrypted config \(previouslyEncrypted)")
            oldRealm = previouslyEncrypted
        }

        if let someEncrypted = try? Realm() {
            print("^^ previouslyEncrypted config \(someEncrypted)")
            oldRealm = someEncrypted
        }

         guard let realm = oldRealm else {
            debugPrint("Relam was not exist")
            return
        }

        // generate new key for encrypting realm
        keychainService.generateNewKey()

        // write copy of realm db
        try? realm.writeCopy(
            toFile: URL(fileURLWithPath: encryptedPath),
            encryptionKey: realmKey
        )

        let configuration = Realm.Configuration(
            fileURL: URL(fileURLWithPath: encryptedPath),
            encryptionKey: realmKey,
            schemaVersion: Constants.schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                log("oldSchemaVersion \(oldSchemaVersion)")
                log("Performing migration \(migration)")
            }
        )

        Realm.Configuration.defaultConfiguration = configuration

        _ = try! Realm(configuration: configuration)
    }

    private func isEncryptedRealmExsist() -> (Bool, path: String?) {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            assertionFailure("No path direction for documentDirectory")
            return (false, nil)
        }

        let encryptedPath = documentDirectory + "/" + Constants.encryptedDBName

        return (fileManager.fileExists(atPath: encryptedPath), encryptedPath)
    }
}
