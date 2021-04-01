//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

// swiftlint:disable force_try
import Foundation
import Promises
import RealmSwift

protocol EncryptedStorageType: DBMigration {
    var storage: Realm { get }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func updateKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func currentToken() -> String?
    func publicKey() -> String?
    func keys() -> Results<KeyInfo>?

    func getAllUsers() -> [UserObject]
    func saveActiveUser(with user: UserObject)
}

final class EncryptedStorage: EncryptedStorageType {
    enum Constants {
        // Encrypted schema version
        static let schemaVersion: UInt64 = 1
        // User object added to schema
        static let schemaVersionUser: UInt64 = 2
        // Account field added to Keys
        static let schemaVersionMultipleAccounts: UInt64 = 3

        static let encryptedDbFilename = "encrypted.realm"
    }

    private let keychainService: KeyChainServiceType
    private let fileManager: FileManager

    private var realmKey: Data {
        keychainService.getStorageEncryptionKey()
    }

    // TODO: - ANTON - Add logger (https://github.com/FlowCrypt/flowcrypt-ios/issues/282)
    private let debugLabel = "[EncryptedStorage][DB Migration]"

    private var encryptedConfiguration: Realm.Configuration {
        let path = getDocumentDirectory() + "/" + Constants.encryptedDbFilename
        let latestSchemaVersion = Constants.schemaVersionMultipleAccounts
        return Realm.Configuration(
            fileURL: URL(fileURLWithPath: path),
            encryptionKey: realmKey,
            schemaVersion: latestSchemaVersion,
            migrationBlock: { [weak self] migration, oldSchemaVersion in
                self?.performSchemaMigration(migration: migration, from: oldSchemaVersion, to: latestSchemaVersion)
            }
        )
    }

    var storage: Realm {
        do {
            Realm.Configuration.defaultConfiguration = encryptedConfiguration
            let realm = try Realm(configuration: encryptedConfiguration)
            return realm
        } catch {
//             destroyEncryptedStorage() - todo - give user option to wipe, don't do it automatically
//             return nil
            fatalError("failed to initiate realm: \(error)")
        }
    }

    init(
        fileManager: FileManager = .default,
        keychainHelper: KeyChainServiceType = KeyChainService()
    ) {
        self.fileManager = fileManager
        self.keychainService = KeyChainService()
    }
}

// MARK: - LogOut
extension EncryptedStorage: LogOutHandler {
    func logOutUser(email: String) throws {
        let users = storage.objects(UserObject.self)

        // in case there is only one user - just delete storage
        if users.count == 1, users.first?.email == email {
            destroyEncryptedStorage()
        } else {
            // remove user and keys for this user
            let userToDelete = users.filter { $0.email == email }
            let keys = storage.objects(KeyInfo.self).filter { $0.account == email }
            let folders = storage.objects(FolderObject.self)
            try storage.write {
                storage.delete(userToDelete)
                storage.delete(keys)
                storage.delete(folders)
            }
        }
    }

    private func destroyEncryptedStorage() {
        do {
            try storage.write {
                storage.deleteAll()
            }
        } catch let error {
            assertionFailure("Error while deleting the objects from the storage \(error)")
        }

        destroyPlainConfigurationIfNeeded()
    }

    /// Remove configuration if user still on plain realm
    private func destroyPlainConfigurationIfNeeded() {
        guard let defaultPath = Realm.Configuration.defaultConfiguration.fileURL else {
            return
        }
        guard defaultPath != self.encryptedConfiguration.fileURL else {
            return
        }
        guard fileManager.fileExists(atPath: defaultPath.absoluteString) else {
            return
        }

        do {
            try fileManager.removeItem(at: defaultPath)
        } catch {
            fatalError("Could not delete configuration for \(defaultPath) with error: \(error)")
        }
    }
}

// MARK: - Migration
extension EncryptedStorage {
    func performMigrationIfNeeded() -> Promise<Void> {
        // current migration only does plain realm -> encrypted realm migration, with no database schema change
        // during next future migration, we can delete this and only focus on database schema migration
        let documentDirectory = getDocumentDirectory()
        let plainRealmPath = documentDirectory + "/default.realm"
        let encryptedRealmPath = documentDirectory + "/" + Constants.encryptedDbFilename
        guard fileManager.fileExists(atPath: plainRealmPath) else {
            debugPrint("Migration not needed: plain realm not used")
            return Promise(())
        }
        guard !fileManager.fileExists(atPath: encryptedRealmPath) else {
            debugPrint("Migration not needed: encrypted realm already set up")
            return Promise(())
        }
        debugPrint("Performing migration from plain to encrypted Realm")
        guard let plainRealm = try? Realm(configuration: Realm.Configuration.defaultConfiguration) else {
            debugPrint("Failed to load plain realm, although the db file was present: destroying")
            destroyEncryptedStorage() // destroys plain as well as encrypted realm (if one existed)
            return Promise(())
        }
        // write encrypted copy of plain realm db
        // encryptionKey is for the NEW copy
        try! plainRealm.writeCopy(toFile: URL(fileURLWithPath: encryptedRealmPath), encryptionKey: realmKey)
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

    private func performSchemaMigration(migration: Migration, from oldSchemaVersion: UInt64, to newVersion: UInt64) {
        debugPrint("\(debugLabel) Check if migration needed from \(oldSchemaVersion) to \(newVersion)")

        guard oldSchemaVersion < newVersion else {
            debugPrint("\(debugLabel) Migration not needed")
            return
        }

        switch newVersion {
        case 0, Constants.schemaVersion, Constants.schemaVersionUser:
            debugPrint("\(debugLabel) Schema Migration not needed")
        case Constants.schemaVersionMultipleAccounts:
            performMultipleAccount(migration: migration)
        default:
            assertionFailure("\(debugLabel) Migration is not implemented for this schema version")
        }
    }

    private func performMultipleAccount(migration: Migration) {
        debugPrint("\(debugLabel) Start Multiple account migration")

        debugPrint("\(debugLabel) - Set isActive = true for a user")
        migration.enumerateObjects(ofType: String(describing: UserObject.self)) { (_, newUser) in
            newUser?["isActive"] = true
        }

        debugPrint("\(debugLabel) - Add account to key")
        migration.enumerateObjects(ofType: String(describing: KeyInfo.self)) { (_, newKey) in
            migration.enumerateObjects(ofType: String(describing: UserObject.self)) { (user, _) in
                newKey?["account"] = user?["email"] ?? ""
            }
        }
    }
}

// MARK: - Keys
extension EncryptedStorage {
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        try! storage.write {
            for key in keyDetails {
                storage.add(try! KeyInfo(key, passphrase: passPhrase, source: source))
            }
        }
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        // KeyInfo doesn't have primaty key, to avoid migration we need to delete keys and then save them

        // delete keys
        keyDetails.forEach { keyDetail in
            try? storage.write {
                storage.delete(storage.objects(KeyInfo.self)
                    .filter("longid=%@", keyDetail.ids[0].longid))
            }
        }

        // add new keys
        try! storage.write {
            for key in keyDetails {
                storage.add(try! KeyInfo(key, passphrase: passPhrase, source: source))
            }
        }
    }

    func keys() -> Results<KeyInfo>? {
        storage.objects(KeyInfo.self)
    }

    func publicKey() -> String? {
        storage.objects(KeyInfo.self)
            .map { $0.public }
            .first
    }
}

// MARK: - Token
extension EncryptedStorage {
    @available(*, deprecated, message: "Use information from UserObject")
    func currentToken() -> String? {
        storage.objects(EmailAccessToken.self).first?.value
    }
}

// MARK: - User
extension EncryptedStorage {
    func getAllUsers() -> [UserObject] {
        Array(storage.objects(UserObject.self))
    }

    func saveActiveUser(with user: UserObject) {
        try! storage.write {
            // Mark all users as inactive
            self.getAllUsers().forEach {
                $0.isActive = false
            }
            self.storage.add(user, update: .all)
        }
    }
}
