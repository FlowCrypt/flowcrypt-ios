//
//  EncryptedStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import RealmSwift
import UIKit

protocol EncryptedStorageType {
    var storage: Realm { get throws }

    var activeUser: User? { get throws }
    func getAllUsers() throws -> [User]
    func saveActiveUser(with user: User) throws
    func doesAnyKeypairExist(for email: String) throws -> Bool

    func putKeypairs(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) throws
    func getKeypairs(by email: String) throws -> [Keypair]
    func removeKeypairs(keypairs: [Keypair]) throws

    func validate() throws
    func cleanup() throws
    func deleteAccount(email: String) throws

    static func removeStorageFile() throws
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
        case version6
        case version7
        case version8
        case version9
        case version10
        case version11
        case version12
        case version13
        case version14
        case version15
        case version16

        var version: SchemaVersion {
            switch self {
            case .initial:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 4)
            case .version5:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 5)
            case .version6:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 6)
            case .version7:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 7)
            case .version8:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 8)
            case .version9:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 9)
            case .version10:
                return SchemaVersion(appVersion: "1.0.7", dbSchemaVersion: 10)
            case .version11:
                return SchemaVersion(appVersion: "1.1.0", dbSchemaVersion: 11)
            case .version12:
                return SchemaVersion(appVersion: "1.1.0", dbSchemaVersion: 12)
            case .version13:
                return SchemaVersion(appVersion: "1.1.1", dbSchemaVersion: 13)
            case .version14:
                return SchemaVersion(appVersion: "1.2.3", dbSchemaVersion: 14)
            case .version15:
                return SchemaVersion(appVersion: "1.2.3", dbSchemaVersion: 15)
            case .version16:
                return SchemaVersion(appVersion: "1.2.3", dbSchemaVersion: 16)
            }
        }
    }

    private lazy var migrationLogger = Logger.nested(in: Self.self, with: .migration)
    private lazy var logger = Logger.nested(Self.self)

    private let currentSchema: EncryptedStorageSchema = .version16
    private let supportedSchemas = EncryptedStorageSchema.allCases

    private let storageEncryptionKey: Data

    var storage: Realm {
        get throws {
            let configuration = try getConfiguration()
            Realm.Configuration.defaultConfiguration = configuration
            return try Realm(configuration: configuration)
        }
    }

    init() async throws {
        let keyProvider = StorageEncryptionKeyProvider()
        self.storageEncryptionKey = try await keyProvider.storageEncryptionKey
    }

    private func getConfiguration() throws -> Realm.Configuration {
        guard !UIApplication.shared.isRunningTests else {
            return Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        }

        let path = try Self.path
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
extension EncryptedStorage {
    func deleteAccount(email: String) throws {
        let storage = try storage

        let users = storage.objects(UserRealmObject.self)

        // in case there is only one user - just delete storage
        if users.count == 1, users.first?.email == email {
            try cleanup()
        } else {
            // remove user and keys for this user
            let userToDelete = users
                .filter { $0.email == email }
            let keys = storage.objects(KeypairRealmObject.self)
                .filter { $0.user?.email == email }
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
}

// MARK: - Schema migration
extension EncryptedStorage {
    private func performSchemaMigration(migration: Migration, from oldSchemaVersion: UInt64, to newVersion: UInt64) {
        migrationLogger.logInfo("Check if migration needed from \(oldSchemaVersion) to \(newVersion)")

        guard oldSchemaVersion < newVersion else {
            migrationLogger.logInfo("Migration not needed")
            return
        }

        let schema = supportedSchemas.first(where: { $0.version.dbSchemaVersion > oldSchemaVersion })
        switch schema {
        case .initial:
            migrationLogger.logInfo("Schema migration not needed for initial schema")
        case .version5:
            SchemaMigration.Version5(migration: migration).perform()
        case .version6:
            SchemaMigration.Version6(migration: migration).perform()
        default:
            break
        }
    }
}

// MARK: - Keys
extension EncryptedStorage {
    func putKeypairs(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) throws {
        guard let user = try getUserObject(for: email) else {
            logger.logError("Can't find user with given email to update keys. User should be already saved")
            return
        }

        let storage = try storage
        try storage.write {
            for key in keyDetails {
                let object = try KeypairRealmObject(key, passphrase: passPhrase, source: source, user: user)
                storage.add(object, update: .all)
            }
        }
    }

    func getKeypairs(by email: String) throws -> [Keypair] {
        return try storage.objects(KeypairRealmObject.self).where {
            $0.user.email == email
        }.map(Keypair.init)
    }

    func removeKeypairs(keypairs: [Keypair]) throws {
        let fingerprintsToBeDeleted = keypairs.map(\.primaryFingerprint)
        let keypairRealmObjectsToDelete = try storage
            .objects(KeypairRealmObject.self)
            .where { keypairRealmObject in
                keypairRealmObject.primaryFingerprint.in(fingerprintsToBeDeleted)
            }
        try storage.write {
            try storage.delete(keypairRealmObjectsToDelete)
        }
    }

    func doesAnyKeypairExist(for email: String) throws -> Bool {
        let keys = try storage.objects(KeypairRealmObject.self).where {
            $0.user.email == email
        }
        return !keys.isEmpty
    }

    private func getUserObject(for email: String) throws -> UserRealmObject? {
        try storage.objects(UserRealmObject.self).where {
            $0.email == email
        }.first
    }

    private func updateKeys(with primaryFingerprint: String, passphrase: String?) throws {
        let keys = try storage.objects(KeypairRealmObject.self).where {
            $0.primaryFingerprint == primaryFingerprint
        }

        try storage.write {
            keys.map { $0.passphrase = passphrase }
        }
    }
}

// MARK: - PassPhrase
extension EncryptedStorage: PassPhraseStorageType {
    func save(passPhrase: PassPhrase) throws {
        try updateKeys(with: passPhrase.primaryFingerprintOfAssociatedKey, passphrase: passPhrase.value)
    }

    func update(passPhrase: PassPhrase) throws {
        try updateKeys(with: passPhrase.primaryFingerprintOfAssociatedKey, passphrase: passPhrase.value)
    }

    func remove(passPhrase: PassPhrase) throws {
        try updateKeys(with: passPhrase.primaryFingerprintOfAssociatedKey, passphrase: nil)
    }

    func getPassPhrases(for email: String, expirationInSeconds _: Int?) throws -> [PassPhrase] {
        return try storage.objects(KeypairRealmObject.self)
            .where { $0.user.email == email }
            .compactMap(PassPhrase.init)
    }

    func removePassPhrases(for email: String) throws {
        let keyPairs = try storage.objects(KeypairRealmObject.self)
            .where { $0.user.email == email }
        for keyPair in keyPairs {
            try updateKeys(with: keyPair.primaryFingerprint, passphrase: nil)
        }
    }
}

// MARK: - User
extension EncryptedStorage {
    var activeUser: User? {
        get throws {
            let users = try storage.objects(UserRealmObject.self).where {
                $0.isActive == true
            }
            return users.first.flatMap(User.init)
        }
    }

    func getAllUsers() throws -> [User] {
        try storage.objects(UserRealmObject.self).map(User.init)
    }

    func saveActiveUser(with user: User) throws {
        let storage = try storage

        try storage.write {
            // Mark all users as inactive
            for storageObject in storage.objects(UserRealmObject.self) {
                storageObject.isActive = false
            }

            let object = UserRealmObject(user)
            object.isActive = true
            storage.add(object, update: .all)
        }
    }
}

extension EncryptedStorage {
    func validate() throws {
        let configuration = try getConfiguration()
        Realm.Configuration.defaultConfiguration = configuration
        _ = try Realm(configuration: configuration)
    }

    func cleanup() throws {
        let storage = try storage

        try storage.write {
            storage.deleteAll()
        }
    }
}

extension EncryptedStorage {
    static var path: String {
        get throws {
            try getDocumentDirectory() + "/encrypted.realm"
        }
    }

    static var doesStorageFileExist: Bool {
        get throws {
            try FileManager.default.fileExists(atPath: path)
        }
    }

    static func getDocumentDirectory() throws -> String {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            throw AppErr.general("No path direction for .documentDirectory")
        }
        return documentDirectory
    }

    static func removeStorageFile() throws {
        try FileManager.default.removeItem(atPath: path)
    }
}
