//
//  LocalClientConfiguration.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

protocol LocalClientConfigurationType {
    func load(for user: String) throws -> RawClientConfiguration?
    func remove(for user: String) throws
    func save(for user: String, raw: RawClientConfiguration, fesUrl: String?) throws
}

final class LocalClientConfiguration {
    private let encryptedStorage: EncryptedStorageType

    private var storage: Realm {
        get throws {
            try encryptedStorage.storage
        }
    }

    init(encryptedStorage: EncryptedStorageType) {
        self.encryptedStorage = encryptedStorage
    }
}

extension LocalClientConfiguration: LocalClientConfigurationType {
    func load(for userEmail: String) throws -> RawClientConfiguration? {
        return try storage.objects(ClientConfigurationRealmObject.self).where {
            $0.userEmail == userEmail
        }.first.flatMap(RawClientConfiguration.init)
    }

    func remove(for userEmail: String) throws {
        let storage = try storage

        let objects = storage.objects(ClientConfigurationRealmObject.self).where {
            $0.userEmail == userEmail
        }

        try storage.write {
            storage.delete(objects)
        }
    }

    func save(for userEmail: String, raw: RawClientConfiguration, fesUrl: String?) throws {
        let object = ClientConfigurationRealmObject(
            configuration: raw,
            email: userEmail,
            fesUrl: fesUrl
        )

        let storage = try storage
        try storage.write {
            storage.add(object, update: .modified)
        }
    }
}
