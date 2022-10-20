//
//  Version5SchemaMigration.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 13.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import RealmSwift

extension SchemaMigration {
    final class Version5 {
        private lazy var logger = Logger.nested(in: Self.self, with: .migration)

        private let migration: Migration

        private var newUsers: [String: MigrationObject] = [:]
        private var newPubKeys: [String: MigrationObject] = [:]

        private var lastError: Error?

        init(migration: Migration) {
            self.migration = migration
        }

        func perform() {
            logger.logInfo("Start version 5 migration")

            let objects: [(String, (MigrationObject) throws -> Void)] = [
                ("UserObject", renameUserObject),
                ("FolderObject", renameFolderObject),
                ("ClientConfigurationObject", renameClientConfigurationObject),
                ("KeyInfo", renameKeyInfo),
                ("PubKeyObject", renamePubKeyObject),
                ("RecipientObject", renameRecipientObject)
            ]
            for object in objects {
                migration.enumerateObjects(ofType: object.0) { oldObject, newObject in
                    guard
                        lastError == nil,
                        let oldObject,
                        newObject == nil
                    else {
                        if lastError == nil {
                            lastError = AppErr.unexpected("Wrong Realm configuration")
                        }
                        return
                    }

                    do {
                        try object.1(oldObject)
                    } catch {
                        lastError = error
                    }
                }
            }

            removeOldObjects()

            guard let error = lastError else {
                logger.logInfo("End version 5 migration")
                return
            }
            logger.logError(error.localizedDescription)
            fatalError(error.localizedDescription)
        }

        private func renameUserObject(oldObject: MigrationObject) throws {
            let newObject = migration.create(UserRealmObject.className())

            let primitiveProperties: [RealmProperty] = [
                Properties.User.isActive,
                Properties.User.name,
                Properties.User.email
            ]
            for property in primitiveProperties {
                newObject[property] = oldObject[property]
            }

            setSession(oldObject: oldObject, newObject: newObject, property: Properties.User.imap)
            setSession(oldObject: oldObject, newObject: newObject, property: Properties.User.smtp)

            guard let primaryKey = oldObject[Properties.User.email] as? String else {
                throw AppErr.unexpected("Wrong UserObject primary key")
            }
            newUsers[primaryKey] = newObject
        }

        private func renameFolderObject(oldObject: MigrationObject) throws {
            let newObject = migration.create(FolderRealmObject.className())

            let primitiveProperties: [RealmProperty] = [
                Properties.Folder.name,
                Properties.Folder.path,
                Properties.Folder.image,
                Properties.Folder.itemType
            ]
            for property in primitiveProperties {
                newObject[property] = oldObject[property]
            }

            try setUser(oldObject: oldObject, newObject: newObject, property: Properties.Folder.user)
        }

        private func renameClientConfigurationObject(oldObject: MigrationObject) throws {
            let newObject = migration.create(ClientConfigurationRealmObject.className())

            let primitiveProperties: [RealmProperty] = [
                Properties.ClientConfiguration.flags,
                Properties.ClientConfiguration.customKeyserverUrl,
                Properties.ClientConfiguration.keyManagerUrl,
                Properties.ClientConfiguration.disallowAttesterSearchForDomains,
                Properties.ClientConfiguration.enforceKeygenAlgo,
                Properties.ClientConfiguration.enforceKeygenExpireMonths,
                Properties.ClientConfiguration.userEmail
            ]
            for property in primitiveProperties {
                newObject[property] = oldObject[property]
            }

            try setUser(oldObject: oldObject, newObject: newObject, property: Properties.ClientConfiguration.user)
        }

        private func renameKeyInfo(oldObject: MigrationObject) throws {
            let newObject = migration.create(KeypairRealmObject.className())

            let primitiveProperties: [RealmProperty] = [
                Properties.Keypair.private,
                Properties.Keypair.public,
                Properties.Keypair.primaryFingerprint,
                Properties.Keypair.passphrase,
                Properties.Keypair.source,
                Properties.Keypair.allFingerprints,
                Properties.Keypair.allLongids
            ]
            for property in primitiveProperties {
                newObject[property] = oldObject[property]
            }

            try setUser(
                oldObject: oldObject,
                newObject: newObject,
                property: Properties.Keypair.user
            )
            try setKeypairObjectPrimaryKey(newObject)
        }

        private func renamePubKeyObject(oldObject: MigrationObject) throws {
            let newObject = migration.create(PubKeyRealmObject.className())

            let primitiveProperties: [RealmProperty] = [
                Properties.PubKey.primaryFingerprint,
                Properties.PubKey.armored,
                Properties.PubKey.lastSig,
                Properties.PubKey.lastChecked,
                Properties.PubKey.expiresOn,
                Properties.PubKey.longids,
                Properties.PubKey.fingerprints,
                Properties.PubKey.created
            ]
            for property in primitiveProperties {
                newObject[property] = oldObject[property]
            }

            guard let primaryKey = oldObject[Properties.PubKey.primaryFingerprint] as? String else {
                throw AppErr.unexpected("Wrong PubKeyObject primary key")
            }
            newPubKeys[primaryKey] = newObject
        }

        private func renameRecipientObject(oldObject: MigrationObject) throws {
            let newObject = migration.create(RecipientRealmObject.className())

            let primitiveProperties: [RealmProperty] = [
                Properties.Recipient.email,
                Properties.Recipient.name,
                Properties.Recipient.lastUsed
            ]
            for property in primitiveProperties {
                newObject[property] = oldObject[property]
            }

            guard let oldPubKeys = oldObject[Properties.Recipient.pubKeys] as? List<MigrationObject> else {
                throw AppErr.unexpected("Wrong RecipientObject pubKeys property")
            }

            let keys: [MigrationObject] = try oldPubKeys.map {
                guard
                    let primaryKey = $0[Properties.PubKey.primaryFingerprint] as? String,
                    let object = newPubKeys[primaryKey]
                else {
                    throw AppErr.unexpected("Wrong PubKeyObject primary key")
                }
                return object
            }

            guard let newPubKeys = newObject[Properties.Recipient.pubKeys] as? List<MigrationObject> else {
                throw AppErr.unexpected("Wrong RecipientRealmObject pubKeys property")
            }
            newPubKeys.append(objectsIn: keys)
        }

        private func removeOldObjects() {
            guard lastError == nil else {
                return
            }

            let types = [
                "ClientConfigurationObject",
                "FolderObject",
                "KeyInfo",
                "UserObject",
                "SessionObject",
                "RecipientObject",
                "PubKeyObject"
            ]
            for type in types where !migration.deleteData(forType: type) {
                logger.logWarning("fail to delete data for type \(type)")
            }
        }

        private func setSession(oldObject: MigrationObject, newObject: MigrationObject, property: RealmProperty) {
            guard let oldSessionObject = oldObject[property] as? Object else {
                return
            }

            newObject[property] = renameSessionObject(oldObject: oldSessionObject)
        }

        private func renameSessionObject(oldObject: Object) -> MigrationObject {
            let newObject = migration.create(SessionRealmObject.className())

            let primitiveProperties: [RealmProperty] = [
                Properties.Session.hostname,
                Properties.Session.port,
                Properties.Session.username,
                Properties.Session.password,
                Properties.Session.oAuth2Token,
                Properties.Session.connectionType,
                Properties.Session.email
            ]
            for property in primitiveProperties {
                newObject[property] = oldObject[property]
            }

            return newObject
        }

        private func setUser(oldObject: MigrationObject, newObject: MigrationObject, property: RealmProperty) throws {
            guard let oldUserObject = oldObject[property] as? Object else {
                return
            }

            guard
                let primaryKey = oldUserObject[Properties.User.email] as? String,
                let object = newUsers[primaryKey]
            else {
                throw AppErr.unexpected("Wrong UserObject primary key")
            }

            newObject[property] = object
        }

        private func setKeypairObjectPrimaryKey(_ object: MigrationObject) throws {
            guard
                let userObject = object[Properties.Keypair.user] as? Object,
                let email = userObject[Properties.User.email] as? String,
                let primaryFingerprint = object[Properties.Keypair.primaryFingerprint] as? String
            else {
                throw AppErr.unexpected("KeypairRealmObject primary key")
            }

            object[Properties.Keypair.primaryKey] = KeypairRealmObject.createPrimaryKey(
                primaryFingerprint: primaryFingerprint,
                email: email
            )
        }
    }
}
