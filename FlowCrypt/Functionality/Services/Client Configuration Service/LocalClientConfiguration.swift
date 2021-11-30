//
//  LocalClientConfiguration.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift
import IDZSwiftCommonCrypto

protocol LocalClientConfigurationType {
    func load(for user: String) -> RawClientConfiguration?
    func remove(for user: String)
    func save(for user: User, raw: RawClientConfiguration)
}

struct LocalClientConfiguration {
    let cache: EncryptedCacheService<ClientConfigurationRealmObject>
    init(encryptedStorage: EncryptedStorageType) {
        self.cache = EncryptedCacheService(encryptedStorage: encryptedStorage)
    }
}

extension LocalClientConfiguration: LocalClientConfigurationType {
    func load(for userEmail: String) -> RawClientConfiguration? {
        guard let foundLocal = cache.getAll(for: userEmail).first else { return nil }
        return RawClientConfiguration(foundLocal)
    }

    func remove(for userEmail: String) {
        cache.removeAll(for: userEmail)
    }

    func save(for user: User, raw: RawClientConfiguration) {
        cache.save(ClientConfigurationRealmObject(configuration: raw, user: user))
    }
}
