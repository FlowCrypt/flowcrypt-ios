//
//  StorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import RealmSwift

// swiftlint:disable force_try
protocol EncryptedStorageType: KeyStorageType {
    var storage: Realm { get }

    func getAllUsers() -> [UserObject]
    func saveActiveUser(with user: UserObject)
    var activeUser: UserObject? { get }
    func doesAnyKeyExist(for email: String) -> Bool

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

        var version: SchemaVersion {
            switch self {
            case .initial:
                return SchemaVersion(appVersion: "0.2.0", dbSchemaVersion: 4)
            }
        }
    }

    private enum Constants {
        static let encryptedDbFilename = "encrypted.realm"
    }

    private let keychainService: KeyChainServiceType

    private lazy var migrationLogger = Logger.nested(in: Self.self, with: .migration)
    private lazy var logger = Logger.nested(Self.self)

    private let currentSchema: EncryptedStorageSchema = .initial
    private let supportedSchemas = EncryptedStorageSchema.allCases

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

    init(keychainHelper: KeyChainServiceType = KeyChainService()) {
        self.keychainService = KeyChainService()
    }

    private func getDocumentDirectory() -> String {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("No path direction for .documentDirectory")
        }
        return documentDirectory
    }

    private func getConfiguration() throws -> Realm.Configuration {
        let path = getDocumentDirectory() + "/" + Constants.encryptedDbFilename
        let key = try keychainService.getStorageEncryptionKey()
        let latestSchemaVersion = currentSchema.version.dbSchemaVersion

        return Realm.Configuration(
            fileURL: URL(fileURLWithPath: path),
            encryptionKey: key,
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
        let users = storage.objects(UserObject.self)

        // in case there is only one user - just delete storage
        if users.count == 1, users.first?.email == email {
            destroyEncryptedStorage()
        } else {
            // remove user and keys for this user
            let userToDelete = users
                .filter { $0.email == email }
            let keys = storage.objects(KeyInfo.self)
                .filter { $0.account == email }
            let sessions = storage.objects(SessionObject.self)
                .filter { $0.email == email }
            let clientConfigurations = storage.objects(ClientConfigurationObject.self)
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
    func addKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
        guard let user = storage.objects(UserObject.self).first(where: { $0.email == email }) else {
            logger.logError("Can't find user with given email to add keys. User should be already saved")
            return
        }
        try! storage.write {
            for key in keyDetails {
                storage.add(try! KeyInfo(key, passphrase: passPhrase, source: source, user: user))
            }
        }
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
        guard let user = getUserObject(for: email) else {
            logger.logError("Can't find user with given email to update keys. User should be already saved")
            return
        }
        try! storage.write {
            for key in keyDetails {
                storage.add(try! KeyInfo(key, passphrase: passPhrase, source: source, user: user), update: .all)
            }
        }
    }

    func updateKeys(with primaryFingerprint: String, passphrase: String?) {
        let keys = keysInfo()
            .filter { $0.primaryFingerprint == primaryFingerprint }

        try! storage.write {
            keys.map { $0.passphrase = passphrase }
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

    func doesAnyKeyExist(for email: String) -> Bool {
        keysInfo()
            .map(\.account)
            .map { $0 == email }
            .contains(true)
    }

    private func getUserObject(for email: String) -> UserObject? {
        storage.objects(UserObject.self).first(where: { $0.email == email })
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
        keysInfo().compactMap(PassPhrase.init)
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
            user.isActive = true
            self.storage.add(user, update: .all)
        }
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
