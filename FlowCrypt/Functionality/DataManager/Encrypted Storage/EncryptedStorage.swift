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

protocol EncryptedStorageType: KeyStorageType {
    var storage: Realm { get }

    func getAllUsers() -> [UserObject]
    func saveActiveUser(with user: UserObject)
    var activeUser: UserObject? { get }

    func cleanup()
}

final class EncryptedStorage: EncryptedStorageType {
    private struct SchemaVersion {
        /// specify app version when schema was applied
        let appVersion: String
        /// current schema version
        let dbSchemaVersion: UInt64
    }

    // new schema should be added as a new case
    private enum EncryptedStorageSchema: CaseIterable {
        case initial

        var version: SchemaVersion {
            switch self {
            case .initial:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 2)
            }
        }
    }

    private enum Constants {
        static let encryptedDbFilename = "encrypted.realm"
    }

    private let keychainService: KeyChainServiceType

    private var realmKey: Data {
        keychainService.getStorageEncryptionKey()
    }

    private lazy var migrationLogger = Logger.nested(in: Self.self, with: .migration)

    private let currentSchema: EncryptedStorageSchema = .initial
    private let supportedSchemas = EncryptedStorageSchema.allCases

    private var encryptedConfiguration: Realm.Configuration {
        let path = getDocumentDirectory() + "/" + Constants.encryptedDbFilename
        let latestSchemaVersion = currentSchema.version.dbSchemaVersion

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

    init(keychainHelper: KeyChainServiceType = KeyChainService()) {
        self.keychainService = KeyChainService()
    }

    private func getDocumentDirectory() -> String {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("No path direction for .documentDirectory")
        }
        return documentDirectory
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
            let userToDelete = users
                .filter { $0.email == email }
            let keys = storage.objects(KeyInfo.self)
                .filter { $0.account.contains(email) }
            let passPhrases = storage.objects(PassPhraseObject.self)
                .filter { keys.map(\.longid).contains($0.longid) }
            let sessions = storage.objects(SessionObject.self)
                .filter { $0.email == email }

            try storage.write {
                storage.delete(userToDelete)
                storage.delete(keys)
                storage.delete(sessions)
                storage.delete(passPhrases)
            }
        }
    }

    private func destroyEncryptedStorage() {
        cleanup()
    }
}

// MARK: - Schema migration
extension EncryptedStorage {
    private func performSchemaMigration(migration: Migration, from oldSchemaVersion: UInt64, to newVersion: UInt64) {
        migrationLogger.logInfo("Check if migration needed from \(oldSchemaVersion) to \(newVersion)")

        guard oldSchemaVersion < newVersion else {
            migrationLogger.logInfo("Migration not needed")
            return
        }

        supportedSchemas.forEach {
            switch $0 {
            case .initial:
                migrationLogger.logInfo("Schema migration not needed for initial schema")
//            case .someNewSchema:
//                performSomeNewSchema(migration: migration)
            }
        }
    }

    private func performSomeNewSchema(migration: Migration) {
        migrationLogger.logInfo("Start Multiple account migration")
    }
}

// MARK: - Keys
extension EncryptedStorage {
    func addKeys(keyDetails: [KeyDetails], source: KeySource) {
        try! storage.write {
            for key in keyDetails {
                storage.add(try! KeyInfo(key, source: source))
            }
        }
    }

    func updateKeys(keyDetails: [KeyDetails], source: KeySource) {
        try! storage.write {
            for key in keyDetails {
                storage.add(try! KeyInfo(key, source: source), update: .all)
            }
        }
    }

    func keysInfo() -> [KeyInfo] {
        let result = storage.objects(KeyInfo.self)
        return Array(result)
    }

    func publicKey() -> String? {
        storage.objects(KeyInfo.self)
            .map(\.public)
            .first
    }
}

// MARK: - PassPhrase
extension EncryptedStorage: EncryptedPassPhraseStorage {
    func addPassPhrase(object: PassPhraseObject) {
        try! storage.write {
            storage.add(object)
        }
    }

    func updatePassPhrase(object: PassPhraseObject) {
        try! storage.write {
            storage.add(object, update: .all)
        }
    }

    func removePassPhrase(object: PassPhraseObject) {
        try! storage.write {
            storage.delete(object)
        }
    }

    func getPassPhrases() -> [PassPhraseObject] {
        Array(storage.objects(PassPhraseObject.self))
    }
}

// MARK: - User
extension EncryptedStorage {
    var activeUser: UserObject? {
        getAllUsers().first(where: \.isActive)
    }

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

extension EncryptedStorage {
    func cleanup() {
        do {
            try storage.write {
                storage.deleteAll()
            }
        } catch {
            assertionFailure("Error while deleting the objects from the storage \(error)")
        }
    }
}
