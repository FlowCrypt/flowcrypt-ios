//
//  DomainRulesProvider.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import RealmSwift

protocol DomainRulesProviderType {
    func fetch() -> DomainRules?
    func removeDomainRules()
    func save(domainRules: DomainRules)
}

struct DomainRulesProvider: CacheServiceType {
    let storage: CacheStorage
    let domainRulesCache: CacheService<DomainRulesObject>

    init(storage: @escaping @autoclosure CacheStorage) {
        self.storage = storage
        self.domainRulesCache = CacheService(storage: storage())
    }
}

extension DomainRulesProvider: DomainRulesProviderType {
    func fetch() -> DomainRules? {
        DomainRules(domainRulesCache.getAllForActiveUser()?.first)
    }

    func removeDomainRules() {
        domainRulesCache.removeAllForActiveUser()
    }

    func save(domainRules: DomainRules) {
        domainRulesCache.save(DomainRulesObject(domainRules, user: EncryptedStorage().activeUser))
    }
}
