//
//  Version6SchemaMigration.swift
//  FlowCrypt
//
//  Created by Ivan Ushakov on 07.12.2021
//  Copyright © 2017-present FlowCrypt a.s. All rights reserved.
//

import FlowCryptCommon
import RealmSwift

extension SchemaMigration {
    final class Version6 {
        private lazy var logger = Logger.nested(in: Self.self, with: .migration)

        private let migration: Migration

        private var users: [String: MigrationObject] = [:]
        private var lastError: Error?

        init(migration: Migration) {
            self.migration = migration
        }

        func perform() {
            logger.logInfo("Start version 6 migration")

            migration.enumerateObjects(ofType: "UserRealmObject") { _, newObject in
                guard
                    lastError == nil,
                    let newObject = newObject
                else {
                    if lastError == nil {
                        lastError = AppErr.unexpected("Wrong Realm configuration")
                    }
                    return
                }

                do {
                    try prepareUserRealmObject(newObject)
                } catch {
                    lastError = error
                }
            }

            let type = "KeyInfoRealmObject"
            migration.enumerateObjects(ofType: type) { oldObject, newObject in
                guard
                    lastError == nil,
                    let oldObject = oldObject,
                    newObject == nil
                else {
                    if lastError == nil {
                        lastError = AppErr.unexpected("Wrong Realm configuration")
                    }
                    return
                }

                do {
                    try renameKeyInfoRealmObject(oldObject)
                } catch {
                    lastError = error
                }
            }

            if !migration.deleteData(forType: type) {
                logger.logWarning("fail to delete data for type \(type)")
            }

            guard let error = lastError else {
                logger.logInfo("End version 6 migration")
                return
            }
            logger.logError(error.localizedDescription)
            fatalError(error.localizedDescription)
        }

        private func prepareUserRealmObject(_ newObject: MigrationObject) throws {
            guard let email = newObject[Properties.User.email] as? String else {
                throw AppErr.unexpected("Wrong UserObject primary key")
            }

            users[email] = newObject
        }

        private func renameKeyInfoRealmObject(_ oldObject: MigrationObject) throws {
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

            guard
                let oldUserObject = oldObject[Properties.Keypair.user] as? Object,
                let email = oldUserObject[Properties.User.email] as? String,
                let userObject = users[email]
            else {
                throw AppErr.unexpected("Wrong UserObject primary key")
            }
            newObject[Properties.Keypair.user] = userObject

            guard
                let userObject = newObject[Properties.Keypair.user] as? Object,
                let email = userObject[Properties.User.email] as? String,
                let primaryFingerprint = newObject[Properties.Keypair.primaryFingerprint] as? String
            else {
                throw AppErr.unexpected("KeypairRealmObject primary key")
            }

            newObject[Properties.Keypair.primaryKey] = KeypairRealmObject.createPrimaryKey(
                primaryFingerprint: primaryFingerprint,
                email: email
            )
        }
    }
}
