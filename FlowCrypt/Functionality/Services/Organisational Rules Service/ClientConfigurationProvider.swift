//
//  ClientConfigurationProvider.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises
import RealmSwift

protocol ClientConfigurationProviderType {
    func fetch() -> ClientConfiguration?
    func removeClientConfiguration()
    func save(clientConfiguration: ClientConfiguration)
}

struct ClientConfigurationProvider: CacheServiceType {
    let storage: CacheStorage
    let clientConfigurationCache: CacheService<ClientConfigurationObject>

    init(storage: @escaping @autoclosure CacheStorage = DataService.shared.storage) {
        self.storage = storage
        self.clientConfigurationCache = CacheService(storage: storage())
    }
}

extension ClientConfigurationProvider: ClientConfigurationProviderType {
    func fetch() -> ClientConfiguration? {
        ClientConfiguration(clientConfigurationCache.getAllForActiveUser()?.first)
    }

    func removeClientConfiguration() {
        clientConfigurationCache.removeAllForActiveUser()
    }

    func save(clientConfiguration: ClientConfiguration) {
        clientConfigurationCache.save(ClientConfigurationObject(clientConfiguration, user: EncryptedStorage().activeUser))
    }
}
