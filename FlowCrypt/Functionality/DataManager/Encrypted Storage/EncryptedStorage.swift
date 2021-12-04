//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import RealmSwift
import UIKit

// swiftlint:disable force_try
protocol EncryptedStorageType {
    var storage: Realm { get }

    var activeUser: User? { get }
    func getAllUsers() -> [User]
    func saveActiveUser(with user: User)
    func doesAnyKeypairExist(for email: String) -> Bool

    func putKeypairs(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String)
    func getKeypairs(by email: String) -> [KeyInfo]

    func find(with email: String) -> Recipient?

    func validate() throws
    func reset() throws
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
        case version5

        var version: SchemaVersion {
            switch self {
            case .initial:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 4)
            case .version5:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 5)
            }
        }
    }

    private enum Constants {
        static let encryptedDbFilename = "encrypted.realm"
    }

    private lazy var migrationLogger = Logger.nested(in: Self.self, with: .migration)
    private lazy var logger = Logger.nested(Self.self)

    private let currentSchema: EncryptedStorageSchema = .version5
    private let supportedSchemas = EncryptedStorageSchema.allCases

    private let storageEncryptionKey: Data

    var storage: Realm {
        do {
            let configuration = try getConfiguration()
            Realm.Configuration.defaultConfiguration = configuration
            let realm = try Realm(configuration: configuration)
            return realm
        } catch {
            fatalError("failed to initiate realm: \(error)")
        }
    }

    init(storageEncryptionKey: Data) {
        self.storageEncryptionKey = storageEncryptionKey
    }

    private func getDocumentDirectory() -> String {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("No path direction for .documentDirectory")
        }
        return documentDirectory
    }

    private func getConfiguration() throws -> Realm.Configuration {
        guard !UIApplication.shared.isRunningTests else {
            return Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        }

        let path = getDocumentDirectory() + "/" + Constants.encryptedDbFilename
        let latestSchemaVersion = currentSchema.version.dbSchemaVersion

        return Realm.Configuration(
            fileURL: URL(fileURLWithPath: path),
            encryptionKey: storageEncryptionKey,
            schemaVersion: latestSchemaVersion,
            migrationBlock: { [weak self] migration, oldSchemaVersion in
                self?.performSchemaMigration(migration: migration, from: oldSchemaVersion, to: latestSchemaVersion)
            }
        )
    }
}

// MARK: - LogOut
extension EncryptedStorage: LogOutHandler {
    func logOutUser(email: String) throws {
        let users = storage.objects(UserRealmObject.self)

        // in case there is only one user - just delete storage
        if users.count == 1, users.first?.email == email {
            destroyEncryptedStorage()
        } else {
            // remove user and keys for this user
            let userToDelete = users
                .filter { $0.email == email }
            let keys = storage.objects(KeyInfoRealmObject.self)
                .filter { $0.account == email }
            let sessions = storage.objects(SessionRealmObject.self)
                .filter { $0.email == email }
            let clientConfigurations = storage.objects(ClientConfigurationRealmObject.self)
                .filter { $0.userEmail == email }

            try storage.write {
                storage.delete(keys)
                storage.delete(sessions)
                storage.delete(clientConfigurations)
                storage.delete(userToDelete)
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
            case .version5:
                Version5SchemaMigration(migration: migration).perform()
            }
        }
    }
}

// MARK: - Keys
extension EncryptedStorage {
    func putKeypairs(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
        guard let user = getUserObject(for: email) else {
            logger.logError("Can't find user with given email to update keys. User should be already saved")
            return
        }
        try! storage.write {
            for key in keyDetails {
                storage.add(try! KeyInfoRealmObject(key, passphrase: passPhrase, source: source, user: user), update: .all)
            }
        }
    }

    func updateKeys(with primaryFingerprint: String, passphrase: String?) {
        let keys = storage.objects(KeyInfoRealmObject.self).where {
            $0.primaryFingerprint == primaryFingerprint
        }

        try! storage.write {
            keys.map { $0.passphrase = passphrase }
        }
    }

    func getKeypairs(by email: String) -> [KeyInfo] {
        return storage.objects(KeyInfoRealmObject.self).where({
            $0.account == email
        }).map(KeyInfo.init)
    }

    func doesAnyKeypairExist(for email: String) -> Bool {
        let keys = storage.objects(KeyInfoRealmObject.self).where {
            $0.account == email
        }
        return !keys.isEmpty
    }

    private func getUserObject(for email: String) -> UserRealmObject? {
        storage.objects(UserRealmObject.self).where {
            $0.email == email
        }.first
    }
}

// MARK: - PassPhrase
extension EncryptedStorage: PassPhraseStorageType {
    func save(passPhrase: PassPhrase) {
        updateKeys(with: passPhrase.primaryFingerprintOfAssociatedKey, passphrase: passPhrase.value)
    }

    func update(passPhrase: PassPhrase) {
        updateKeys(with: passPhrase.primaryFingerprintOfAssociatedKey, passphrase: passPhrase.value)
    }

    func remove(passPhrase: PassPhrase) {
        updateKeys(with: passPhrase.primaryFingerprintOfAssociatedKey, passphrase: nil)
    }

    func getPassPhrases() -> [PassPhrase] {
        return storage.objects(KeyInfoRealmObject.self)
            .compactMap(PassPhrase.init)
    }
}

// MARK: - User
extension EncryptedStorage {
    var activeUser: User? {
        let users = storage.objects(UserRealmObject.self).where {
            $0.isActive == true
        }
        return users.first.flatMap(User.init)
    }

    func getAllUsers() -> [User] {
        storage.objects(UserRealmObject.self).map(User.init)
    }

    func saveActiveUser(with user: User) {
        try! storage.write {
            // Mark all users as inactive
            storage.objects(UserRealmObject.self).forEach {
                $0.isActive = false
            }

            let object = UserRealmObject(user)
            object.isActive = true
            storage.add(object, update: .all)
        }
    }
}

// MARK: - Recipient
extension EncryptedStorage {
    func find(with email: String) -> Recipient? {
        storage.object(
            ofType: RecipientRealmObject.self,
            forPrimaryKey: email
        ).map(Recipient.init)
    }
}

extension EncryptedStorage {
    func validate() throws {
        let configuration = try getConfiguration()
        Realm.Configuration.defaultConfiguration = configuration
        _ = try Realm(configuration: configuration)
    }

    func reset() throws {
        let path = getDocumentDirectory() + "/" + Constants.encryptedDbFilename
        try FileManager.default.removeItem(atPath: path)
    }

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
