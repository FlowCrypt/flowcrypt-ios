//
//  CacheService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: - CachedRealmObject
protocol CachedRealmObject: Object {
    associatedtype Identifier: Equatable
    var identifier: Identifier { get }
    var activeUser: UserRealmObject? { get }
}

// MARK: - Cache
final class EncryptedCacheService<T: CachedRealmObject> {
    let encryptedStorage: EncryptedStorageType
    var realm: Realm { encryptedStorage.storage }

    init(encryptedStorage: EncryptedStorageType) {
        self.encryptedStorage = encryptedStorage
    }

    func save(_ object: T) {
        // todo - should throw instead, don't "try?"
        try? realm.write {
            realm.add(object, update: .modified)
        }
    }

    func remove(object: T, with identifier: T.Identifier) {
        guard let objectToDelete = realm
            .objects(T.self)
            .first(where: { $0.identifier == identifier })
        else { return }

        // todo - should throw instead, don't "try?"
        try? realm.write {
           realm.delete(objectToDelete)
        }
    }

    func remove(objects: [T]) {
        // todo - should throw instead, don't "try?"
        try? realm.write {
            realm.delete(objects)
        }
    }

    func removeAll(for userEmail: String) {
        let allObjects = getAll(for: userEmail)
        remove(objects: allObjects)
    }

    func getAll(for userEmail: String) -> [T] {
        return Array(realm.objects(T.self))
            .filter { $0.activeUser?.email == userEmail }
    }
}
