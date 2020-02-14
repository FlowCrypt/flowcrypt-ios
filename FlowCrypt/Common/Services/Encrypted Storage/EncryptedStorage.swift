//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift
import Promises

protocol DBMigration {
    func performMigrationIfNeeded() -> Promise<Void>
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
        static let encryptedDbFilename = "encrypted.realm"
    }

    let keychainService: KeyChainServiceType
    private let fileManager: FileManager

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

    private var encryptedConfiguration: Realm.Configuration {
        let path = getDocumentDirectory() + "/" + Constants.encryptedDbFilename
        return Realm.Configuration(
            fileURL: URL(fileURLWithPath: path),
            encryptionKey: realmKey,
            schemaVersion: Constants.schemaVersion
        )
    }

    private var storage: Realm {
        do {
            return try Realm(configuration: self.encryptedConfiguration)
        } catch let error {
//             destroyEncryptedStorage() - todo - give user option to wipe, don't do it automatically
//             return nil
            fatalError("failed to initiate realm: \(error)")
        }
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        try! storage.write {
            for k in keyDetails {
                storage.add(try! KeyInfo(k, passphrase: passPhrase, source: source))
            }
        }
    }

    func publicKey() -> String? {
        return storage.objects(KeyInfo.self)
            .map { $0.public }
            .first 
    }

    func keys() -> Results<KeyInfo>? {
        return storage.objects(KeyInfo.self)
    }

    func saveToken(with string: String?) {
        guard let token = string else {
            logOut()
            return
        }
        try! storage.write {
            self.storage.add(EmailAccessToken(value: token))
        }
    }

    func currentToken() -> String? {
        storage.objects(EmailAccessToken.self).first?.value
    }
}

extension EncryptedStorage: LogOutHandler {
    func logOut() { // todo - logOut is not clear - should be called onLogOut to make it clear it's responding to an event
        destroyEncryptedStorage()
    }

    private func destroyEncryptedStorage() {
        destroyStorage(at: Realm.Configuration.defaultConfiguration.fileURL!) // todo - remove this line in version 0.1.8
        destroyStorage(at: self.encryptedConfiguration.fileURL!)
    }

    private func destroyStorage(at url: URL) {
        do {
            try fileManager.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
//            debugPrint("Realm at url \(url) did not exist")
        } catch let error {
            fatalError("Could not delete configuration for \(url) with error: \(error)")
        }
    }
}

extension EncryptedStorage {
    func performMigrationIfNeeded() -> Promise<Void> {
        // current migration only does plain realm -> encrypted realm migration, with no database schema change
        // during next future migration, we can delete this and only focus on database schema migration
        let documentDirectory = self.getDocumentDirectory()
        let plainRealmPath = documentDirectory + "/default.realm"
        let encryptedRealmPath = documentDirectory + "/" + Constants.encryptedDbFilename
        guard self.fileManager.fileExists(atPath: plainRealmPath) else {
            debugPrint("Migration not needed: plain realm not used")
            return Promise(())
        }
        guard !self.fileManager.fileExists(atPath: encryptedRealmPath) else {
            debugPrint("Migration not needed: encrypted realm already set up")
            return Promise(())
        }
        debugPrint("Performing migration from plain to encrypted Realm")
        guard let plainRealm = try? Realm.init(configuration: Realm.Configuration.defaultConfiguration) else {
            debugPrint("Failed to load plain realm, although the db file was present: destroying")
            self.destroyEncryptedStorage() // destroys plain as well as encrypted realm (if one existed)
            return Promise(())
        }
        // write encrypted copy of plain realm db
        try! plainRealm.writeCopy(toFile: URL(fileURLWithPath: encryptedRealmPath), encryptionKey: self.realmKey) // encryptionKey is for the NEW copy
        // launch configuration and perform schema migration if needed
        return Promise<Void> { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }
            let configuration = Realm.Configuration(
                fileURL: URL(fileURLWithPath: encryptedRealmPath),
                encryptionKey: self.realmKey,
                schemaVersion: Constants.schemaVersion,
                migrationBlock: { migration, oldSchemaVersion in
                    do {
                        debugPrint("oldSchemaVersion \(oldSchemaVersion)")
                        debugPrint("Performing migration \(migration)")
                        // I'd rather the app crashes then to pretend it has removed the plain copy
                        // todo - remove the following line for migrations from 0.1.7 up
                        try self.fileManager.removeItem(atPath: plainRealmPath) // delete previous configuration
                        resolve(())
                    } catch {
                        reject(error)
                    }
                }
            )
            _ = try Realm(configuration: configuration) // runs migration and calls completion block
        }
    }

    private func getDocumentDirectory() -> String {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("No path direction for .documentDirectory")
        }
        return documentDirectory
    }

}
