//
//  CacheService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

typealias CacheStorage = () -> Realm

protocol CacheServiceType {
    var storage: CacheStorage { get }
}

// MARK: - CachedObject
protocol CachedObject: Object {
    associatedtype Identifier: Equatable
    var identifier: Identifier { get }
    var activeUser: UserObject? { get }
}

// MARK: - Cache
final class CacheService<T: CachedObject>: CacheServiceType {
    let storage: CacheStorage

    init(storage: @escaping @autoclosure CacheStorage) {
        self.storage = storage
    }

    func save(_ object: T) {
        let realm = storage()

        try? realm.write {
            realm.add(object, update: .modified)
        }
    }

    func retreive(for identifier: T.Identifier) -> T? {
        getAll()?.first(where: { $0.identifier == identifier })
    }

    func remove(object: T, with identifier: T.Identifier) {
        let realm = storage()
        guard let objectToDelete = realm
            .objects(T.self)
            .first(where: { $0.identifier == identifier })
        else { return }

        try? realm.write {
           realm.delete(objectToDelete)
        }
    }

    func remove(objects: [T]) {
        let realm = storage()

        try? realm.write {
            realm.delete(objects)
        }
    }

    func removeAllForActiveUser() {
        let allObjects = getAllForActiveUser() ?? []
        remove(objects: allObjects)
    }

    func getAll() -> [T]? {
        Array(storage().objects(T.self))
    }

    func getAllForActiveUser() -> [T]? {
        let currentUser = storage()
            .objects(UserObject.self)
            .first(where: \.isActive)

        return Array(storage().objects(T.self))
            .filter { $0.activeUser?.email == currentUser?.email }
    }
}
