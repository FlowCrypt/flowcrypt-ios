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
    func performMigrationIfNeeded(_ completion: @escaping () -> Void)
}

protocol EncryptedStorageType: DBMigration {
    var isEncrypted: Bool { get }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func saveToken(with string: String?)
    func currentToken() -> String?
    func publicKey() -> String?
    func keys() -> Results<KeyInfo>?
}

final class EncryptedStorage: EncryptedStorageType {
    enum Constants {
        static let schemaVersion: UInt64 = 1
        static let encryptedDBName = "encrypted.realm"
    }

    let keychainService: KeyChainServiceType
    private let fileManager: FileManager

    var isEncrypted: Bool {
        encryptedConfiguration?.encryptionKey != nil
    }

    init(
        fileManager: FileManager = .default,
        keychainHelper: KeyChainServiceType = KeyChainService()
    ) {
        self.fileManager = fileManager
        self.keychainService = KeyChainService()
    }

    private var realmKey: Data {
        keychainService.getStorageEncryptionKey()
    }

    private var encryptedConfiguration: Realm.Configuration? {
        guard let path = pathForEncryptedRealm() else {
            fatalError("Path for encrypted Realm can't be created")
        }

        return Realm.Configuration(
            fileURL: URL(fileURLWithPath: path),
            encryptionKey: realmKey,
            schemaVersion: Constants.schemaVersion
        )
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
            .forEach {
                destroyStorage(at: $0)
            }
    }

    private func destroyStorage(at url: URL) {
        do {
            try fileManager.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
            debugPrint("Realm at url \(url) not existed")
        } catch let error {
            fatalError("Could not delete configuration for \(url) with error: \(error)")
        }
    }
}

extension EncryptedStorage {
    func performMigrationIfNeeded(_ completion: @escaping () -> Void) {
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
            completion()
            return
        }

        if !isEncryptedRealmExsist && !isUnencryptedRealmExsist {
            debugPrint("Realm was not exist")
            destroyEncryptedStorage()
            completion()
            return
        }

        debugPrint("Performing migration")

        var oldRealm: Realm? = nil

        if let defaultRealm = try? Realm.init(configuration: Realm.Configuration.defaultConfiguration) {
            oldRealm = defaultRealm
        }
 
        if let key = keychainService.getOldKeychainKey() {
            if let previouslyEncrypted = try? Realm(configuration: Realm.Configuration(encryptionKey: key)) {
                debugPrint("use previouslyEncrypted config \(previouslyEncrypted) for migration")
                oldRealm = previouslyEncrypted
            }
        }

         guard let realm = oldRealm else {
            debugPrint("Relam was not exist. Migration not needed")
            completion()
            return
        }

        // write copy of realm db
        do {
            try realm.writeCopy(
                toFile: URL(fileURLWithPath: encryptedPath),
                encryptionKey: realmKey
            )
        } catch let error {
            debugPrint(error)
        }

        // launch configuration and perform migration if needed
        let configuration = Realm.Configuration(
            fileURL: URL(fileURLWithPath: encryptedPath),
            encryptionKey: realmKey,
            schemaVersion: Constants.schemaVersion,
            migrationBlock: { [weak self] migration, oldSchemaVersion in
                debugPrint("oldSchemaVersion \(oldSchemaVersion)")
                debugPrint("Performing migration \(migration)")
                // delete previous configuration
                try? self?.fileManager.removeItem(atPath: unencryptedRealmPath)
                completion()
            }
        ) 

        _ = try! Realm(configuration: configuration)
    }

    private func isEncryptedRealmExsist() -> Bool {
        guard let encryptedPath = pathForEncryptedRealm() else { return false }
        return fileManager.fileExists(atPath: encryptedPath)
    }

    private func pathForEncryptedRealm() -> String? {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            assertionFailure("No path direction for documentDirectory")
            return nil
        }

        return documentDirectory + "/" + Constants.encryptedDBName
    }
}
