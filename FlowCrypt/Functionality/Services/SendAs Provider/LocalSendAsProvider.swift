//
//  LocalSendAsProvider.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 06/13/22.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

protocol LocalSendAsProviderType {
    func fetchList(for userEmail: String) throws -> [SendAsModel]
    func removeList(for userEmail: String) throws
    func save(list: [SendAsModel], for user: User) throws
}

final class LocalSendAsProvider {
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

extension LocalSendAsProvider: LocalSendAsProviderType {
    func fetchList(for userEmail: String) throws -> [SendAsModel] {
        try storage.objects(SendAsRealmObject.self).where {
            $0.user.email == userEmail
        }.compactMap(SendAsModel.init)
    }

    func save(list: [SendAsModel], for user: User) throws {
        let objects = list.map { SendAsRealmObject(sendAs: $0, user: user) }
        let storage = try storage
        try storage.write {
            for object in objects {
                storage.add(object, update: .modified)
            }
        }
    }

    func removeList(for userEmail: String) throws {
        let storage = try storage

        let objects = storage.objects(SendAsRealmObject.self).where {
            $0.user.email == userEmail
        }

        try storage.write {
            storage.delete(objects)
        }
    }
}
