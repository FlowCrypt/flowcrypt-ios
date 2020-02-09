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
        static let schemaVersion: UInt64 = 1
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
        guard canHaveAccessToStorage else { return nil }
        return Realm.Configuration(encryptionKey: realmKey)
    }

    var storage: Realm? {
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

extension EncryptedStorage {
    func performMigrationIfNeeded() {
        let encryptedConf = encryptedConfiguration

        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            assertionFailure("No path direction for documentDirectory")
            return
        }

        let unencryptedRealmPath = documentDirectory + "/default.realm"
        let encryptedPath = documentDirectory + "/encrypted.realm"

        let isUnencryptedRealmExsist = fileManager.fileExists(atPath: unencryptedRealmPath)
        let isEncryptedRealmExsist = fileManager.fileExists(atPath: encryptedPath)

        guard isUnencryptedRealmExsist && !isEncryptedRealmExsist else {
            debugPrint("Migration not needed")
            return
        }

        debugPrint("Perform migration")
        guard let realm = storage else {
            debugPrint("Relam was not exist")
            return
        }
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

        _ = try! Realm(configuration: configuration)




        /*
                // Get the encryptionKey
                var realmKey = Keychain.realmKey
                if realmKey == nil {
                    var key = Data(count: 64)

                    key.withUnsafeMutableBytes { (bytes) -> Void in
                        _ = SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
                    }
                    realmKey = key
                    Keychain.realmKey = realmKey
                }


                // Check if the user has the unencrypted Realm
                let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let fileManager = FileManager.default
                let unencryptedRealmPath = "\(documentDirectory)/default.realm"
                let encryptedPath = "\(documentDirectory)/default_new.realm"
                let isUnencryptedRealmExsist = fileManager.fileExists(atPath: unencryptedRealmPath)
                let isEncryptedRealmExsist = fileManager.fileExists(atPath: encryptedPath)


                if isUnencryptedRealmExsist && !isEncryptedRealmExsist {
                    let unencryptedRealm = try! Realm(configuration: Realm.Configuration(schemaVersion: 7))
                    // if the user has unencrypted Realm write a copy to new path
                    try? unencryptedRealm.writeCopy(toFile: URL(fileURLWithPath: encryptedPath), encryptionKey: realmKey)
                }

                // read from the new encrypted Realm path
                let configuration = Realm.Configuration(fileURL: URL(fileURLWithPath: encryptedPath), encryptionKey: realmKey, schemaVersion: 7, migrationBlock: { migration, oldSchemaVersion in })

                return try! Realm(configuration: configuration)
                */
    }
}
