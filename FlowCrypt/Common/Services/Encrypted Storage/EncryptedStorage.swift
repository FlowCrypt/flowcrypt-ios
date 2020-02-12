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
        static let encryptedDbFilename = "encrypted.realm"
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
        let path = getDocumentDirectory() + "/" + Constants.encryptedDbFilename
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
            debugPrint("Realm at url \(url) did not exist")
        } catch let error {
            fatalError("Could not delete configuration for \(url) with error: \(error)")
        }
    }
}

extension EncryptedStorage {
    func performMigrationIfNeeded(_ completion: @escaping () -> Void) {
        // current migration only does plain realm -> encrypted realm migration, with no database schema change
        // during next future migration, we can delete this and only focus on database schema migration
        let documentDirectory = getDocumentDirectory()
        let plainRealmPath = documentDirectory + "/default.realm"
        let encryptedRealmPath = documentDirectory + "/" + Constants.encryptedDbFilename
        guard fileManager.fileExists(atPath: plainRealmPath) else {
            debugPrint("Migration not needed: plain realm not used")
            completion()
            return
        }
        guard !fileManager.fileExists(atPath: encryptedRealmPath) else {
            debugPrint("Migration not needed: encrypted realm already set up")
            completion()
            return
        }
        debugPrint("Performing migration from plain to encrypted Realm")
        guard let plainRealm = try? Realm.init(configuration: Realm.Configuration.defaultConfiguration) else {
            debugPrint("Failed to load plain realm, although the db file was present: destroying")
            destroyEncryptedStorage() // destroys plain as well as encrypted realm (if one existed)
            completion()
            return
        }
        // write encrypted copy of plain realm db
        try! plainRealm.writeCopy(toFile: URL(fileURLWithPath: encryptedRealmPath), encryptionKey: realmKey) // encryptionKey is for the NEW copy
        // launch configuration and perform schema migration if needed
        let configuration = Realm.Configuration(
            fileURL: URL(fileURLWithPath: encryptedRealmPath),
            encryptionKey: realmKey,
            schemaVersion: Constants.schemaVersion,
            migrationBlock: { [weak self] migration, oldSchemaVersion in
                debugPrint("oldSchemaVersion \(oldSchemaVersion)")
                debugPrint("Performing migration \(migration)")
                // I'd rather the app crashes then to pretend it has removed the plain copy
                // todo - remove the following line for migrations from 0.1.7 up
                try! self!.fileManager.removeItem(atPath: plainRealmPath) // delete previous configuration
                completion()
            }
        )
        _ = try! Realm(configuration: configuration) // runs migration and calls completion block
    }

    private func getDocumentDirectory() -> String {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("No path direction for .documentDirectory")
        }
        return documentDirectory
    }

}
