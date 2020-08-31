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
}

// MARK: - Cache
struct CacheService<T: CachedObject>: CacheServiceType {
    let storage: () -> Realm

    init(storage: @escaping @autoclosure () -> Realm) {
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

    func getAll() -> [T]? {
        Array(storage().objects(T.self))
    }
}

// MARK: - Object

final class FolderObject: Object {

}

extension FolderObject: CachedObject {
    var identifier: String { "Identifier" }
}

// MARK: - Struct
//struct Folder {
//
//}
//
//extension Folder: CachedObject {
//    func mapToObject() -> FolderObject {
//        FolderObject()
//    }
//
//    var identifier: String { "Identifier" }
//}

// MARK: - Test
final class ATestClass {
    let cache = CacheService<FolderObject>(storage: DataService.shared.storage)

    func doSmth() {
        let folder = cache.retreive(for: "INBOX")
        let all = cache.getAll()
    }
}
