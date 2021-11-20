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
    func load() -> RawClientConfiguration?
    func remove()
    func save(raw: RawClientConfiguration)
}

struct LocalClientConfiguration {
    let cache: EncryptedCacheService<ClientConfigurationRealmObject>
    init(encryptedStorage: EncryptedStorageType = EncryptedStorage()) {
        self.cache = EncryptedCacheService(encryptedStorage: encryptedStorage)
    }
}

extension LocalClientConfiguration: LocalClientConfigurationType {
    func load() -> RawClientConfiguration? {
        // (tom) todo - should we not guard here?
//        guard let user = cache.encryptedStorage.activeUser else {
//            fatalError("Internal inconsistency, no active user when loading client configuration")
//        }
        RawClientConfiguration(cache.getAllForActiveUser()?.first)
    }

    func remove() {
        // (tom) todo - should we not guard here?
        cache.removeAllForActiveUser()
    }

    func save(raw: RawClientConfiguration) {
        guard let user = cache.encryptedStorage.activeUser else {
            fatalError("Internal inconsistency, no active user when saving client configuration")
        }
        cache.save(ClientConfigurationRealmObject(configuration: raw, user: user))
    }
}
