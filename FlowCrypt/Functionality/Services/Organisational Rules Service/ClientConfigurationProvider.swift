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

struct ClientConfigurationProvider {
    let clientConfigurationCache: CacheService<ClientConfigurationObject>

    init(encryptedStorage: EncryptedStorageType = EncryptedStorage()) {
        self.clientConfigurationCache = CacheService(encryptedStorage: encryptedStorage)
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
        guard let user = clientConfigurationCache.encryptedStorage.activeUser else {
            assertionFailure("Internal inconsistency. Missed client configuration")
            return
        }
        clientConfigurationCache.save(ClientConfigurationObject(clientConfiguration, user: user))
    }
}
