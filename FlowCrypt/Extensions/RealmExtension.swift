//
//  RealmExtension.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 09.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Realm
import RealmSwift

protocol RealmListDetachable {
    func detached() -> Self
}

extension List: RealmListDetachable where Element: Object {
    func detached() -> List<Element> {
        let detached = self.detached
        let result = List<Element>()
        result.append(objectsIn: detached)
        return result
    }
}

extension Object {
    // TODO Temporary solution from StackOverflow for https://github.com/FlowCrypt/flowcrypt-ios/issues/877
    func detached() -> Self {
        let detached = type(of: self).init()
        for property in objectSchema.properties {
            guard
                property != objectSchema.primaryKeyProperty,
                let value = value(forKey: property.name)
            else { continue }

            if let detachable = value as? Object {
                detached.setValue(detachable.detached(), forKey: property.name)
            } else if let list = value as? RealmListDetachable {
                detached.setValue(list.detached(), forKey: property.name)
            } else {
                detached.setValue(value, forKey: property.name)
            }
        }
        return detached
    }
}

extension Sequence where Iterator.Element: Object {
    var detached: [Element] {
        return self.map({ $0.detached() })
    }
}
