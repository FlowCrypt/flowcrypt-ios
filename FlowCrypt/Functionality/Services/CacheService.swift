//
//  CacheService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: - CachedObject
protocol CachedObject: Object {
    associatedtype Identifier: Equatable
    var identifier: Identifier { get }
    var activeUser: UserObject? { get }
}

// MARK: - Cache
final class CacheService<T: CachedObject> {
    let encryptedStorage: EncryptedStorageType
    var realm: Realm { encryptedStorage.storage }

    init(encryptedStorage: EncryptedStorageType) {
        self.encryptedStorage = encryptedStorage
    }

    func save(_ object: T) {
        try? realm.write {
            realm.add(object, update: .modified)
        }
    }

    func retreive(for identifier: T.Identifier) -> T? {
        getAll()?.first(where: { $0.identifier == identifier })
    }

    func remove(object: T, with identifier: T.Identifier) {
        guard let objectToDelete = realm
            .objects(T.self)
            .first(where: { $0.identifier == identifier })
        else { return }

        try? realm.write {
           realm.delete(objectToDelete)
        }
    }

    func remove(objects: [T]) {
        try? realm.write {
            realm.delete(objects)
        }
    }

    func removeAllForActiveUser() {
        let allObjects = getAllForActiveUser() ?? []
        remove(objects: allObjects)
    }

    func getAll() -> [T]? {
        Array(realm.objects(T.self))
    }

    func getAllForActiveUser() -> [T]? {
        let currentUser = realm
            .objects(UserObject.self)
            .first(where: \.isActive)

        return Array(realm.objects(T.self))
            .filter { $0.activeUser?.email == currentUser?.email }
    }
}
