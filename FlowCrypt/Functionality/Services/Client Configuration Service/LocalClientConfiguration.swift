//
//  LocalClientConfiguration.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

protocol LocalClientConfigurationType {
    func load(for user: String) -> RawClientConfiguration?
    func remove(for user: String) throws
    func save(for user: User, raw: RawClientConfiguration, fesUrl: String?) throws
}

final class LocalClientConfiguration {
    private let encryptedStorage: EncryptedStorageType

    private var storage: Realm {
        encryptedStorage.storage
    }

    init(encryptedStorage: EncryptedStorageType) {
        self.encryptedStorage = encryptedStorage
    }
}

extension LocalClientConfiguration: LocalClientConfigurationType {
    func load(for userEmail: String) -> RawClientConfiguration? {
        return storage.objects(ClientConfigurationRealmObject.self).where {
            $0.userEmail == userEmail
        }.first.flatMap(RawClientConfiguration.init)
    }

    func remove(for userEmail: String) throws {
        let objects = storage.objects(ClientConfigurationRealmObject.self).where {
            $0.userEmail == userEmail
        }

        try storage.write {
            storage.delete(objects)
        }
    }

    func save(for user: User, raw: RawClientConfiguration, fesUrl: String?) throws {
        let object = ClientConfigurationRealmObject(
            configuration: raw,
            user: user,
            fesUrl: fesUrl
        )

        try storage.write {
            storage.add(object, update: .modified)
        }
    }
}
