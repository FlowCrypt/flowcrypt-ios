//
//  Version5SchemaMigration.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 13.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import RealmSwift

final class Version5SchemaMigration {
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
            ("PubKeyObject", renamePubKeyObject)
        ]
        objects.forEach { object in
            migration.enumerateObjects(ofType: object.0) { oldObject, newObject in
                guard
                    lastError == nil,
                    let oldObject = oldObject,
                    newObject == nil
                else {
                    lastError = AppErr.unexpected("Wrong Realm configuration")
                    return
                }

                do {
                    try object.1(oldObject)
                } catch {
                    lastError = error
                }
            }
        }

        guard let error = lastError else {
            logger.logInfo("End version 5 migration")
            return
        }
        logger.logError(error.localizedDescription)
        fatalError(error.localizedDescription)
    }

    private func renameUserObject(oldObject: MigrationObject) throws {
        let newObject = migration.create(UserRealmObject.className())

        let primitiveProperties: [String] = [
            "isActive",
            "name",
            "email"
        ]
        primitiveProperties.forEach {
            newObject[$0] = oldObject[$0]
        }

        setSession(oldObject: oldObject, newObject: newObject, propertyName: "imap")
        setSession(oldObject: oldObject, newObject: newObject, propertyName: "smtp")

        guard let primaryKey = oldObject["email"] as? String else {
            throw AppErr.unexpected("Wrong UserObject primary key")
        }
        newUsers[primaryKey] = newObject
    }

    private func renameFolderObject(oldObject: MigrationObject) throws {
        let newObject = migration.create(FolderRealmObject.className())

        let primitiveProperties: [String] = [
            "name",
            "path",
            "image",
            "itemType"
        ]
        primitiveProperties.forEach {
            newObject[$0] = oldObject[$0]
        }

        try setUser(oldObject: oldObject, newObject: newObject, propertyName: "user")
    }

    private func renameClientConfigurationObject(oldObject: MigrationObject) throws {
        let newObject = migration.create(ClientConfigurationRealmObject.className())

        let primitiveProperties: [String] = [
            "flags",
            "customKeyserverUrl",
            "keyManagerUrl",
            "disallowAttesterSearchForDomains",
            "enforceKeygenAlgo",
            "enforceKeygenExpireMonths",
            "userEmail"
        ]
        primitiveProperties.forEach {
            newObject[$0] = oldObject[$0]
        }

        try setUser(oldObject: oldObject, newObject: newObject, propertyName: "user")
    }

    private func renameKeyInfo(oldObject: MigrationObject) throws {
        let newObject = migration.create(KeyInfoRealmObject.className())

        let primitiveProperties: [String] = [
            "private",
            "public",
            "primaryFingerprint",
            "passphrase",
            "source"
        ]
        primitiveProperties.forEach {
            newObject[$0] = oldObject[$0]
        }

        try setUser(oldObject: oldObject, newObject: newObject, propertyName: "user")
    }

    private func renamePubKeyObject(oldObject: MigrationObject) throws {
        let newObject = migration.create(PubKeyRealmObject.className())

        let primitiveProperties: [String] = [
            "primaryFingerprint",
            "armored",
            "lastSig",
            "lastChecked",
            "expiresOn",
            "longids",
            "fingerprints",
            "created"
        ]
        primitiveProperties.forEach {
            newObject[$0] = oldObject[$0]
        }

        guard let primaryKey = oldObject["primaryFingerprint"] as? String else {
            throw AppErr.unexpected("Wrong PubKeyObject primary key")
        }
        newPubKeys[primaryKey] = newObject
    }

    private func renameRecipientObject(oldObject: MigrationObject) throws {
        let newObject = migration.create(RecipientRealmObject.className())

        let primitiveProperties: [String] = [
            "name",
            "lastUsed"
        ]
        primitiveProperties.forEach {
            newObject[$0] = oldObject[$0]
        }

        guard let oldPubKeys = oldObject["pubKeys"] as? List<Object> else {
            throw AppErr.unexpected("Wrong RecipientObject pubKeys property")
        }

        let keys: [MigrationObject] = try oldPubKeys.map({
            guard
                let primaryKey = $0["primaryFingerprint"] as? String,
                let object = newPubKeys[primaryKey]
            else {
                throw AppErr.unexpected("Wrong PubKeyObject primary key")
            }
            return object
        })

        guard let newPubKeys = newObject["pubKeys"] as? List<Object> else {
            throw AppErr.unexpected("Wrong RecipientRealmObject pubKeys property")
        }
        newPubKeys.append(objectsIn: keys)
    }

    private func setSession(oldObject: MigrationObject, newObject: MigrationObject, propertyName: String) {
        guard let oldSessionObject = oldObject[propertyName] as? Object else {
            return
        }

        newObject[propertyName] = renameSessionObject(oldObject: oldSessionObject)
    }

    private func renameSessionObject(oldObject: Object) -> MigrationObject {
        let newObject = migration.create(SessionRealmObject.className())

        let primitiveProperties: [String] = [
            "hostname",
            "port",
            "username",
            "password",
            "oAuth2Token",
            "connectionType",
            "email"
        ]
        primitiveProperties.forEach {
            newObject[$0] = oldObject[$0]
        }

        return newObject
    }

    private func setUser(oldObject: MigrationObject, newObject: MigrationObject, propertyName: String) throws {
        guard let oldUserObject = oldObject[propertyName] as? Object else {
            return
        }

        guard
            let primaryKey = oldUserObject["email"] as? String,
            let object = newUsers[primaryKey]
        else {
            throw AppErr.unexpected("Wrong UserObject primary key")
        }

        newObject[propertyName] = object
    }
}
