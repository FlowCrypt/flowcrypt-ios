//
//  CollectionExtensions.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 23/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public extension Collection {
    subscript(safe index: Index) -> Iterator.Element? {
        indices.contains(index)
            ? self[index]
            : nil
    }

    var isNotEmpty: Bool { !isEmpty }
}

public extension MutableCollection {
    subscript(safe index: Index) -> Iterator.Element? {
        set {
            if indices.contains(index), let newValue = newValue {
                self[index] = newValue
            }
        }
        get {
            return indices.contains(index)
                ? self[index]
                : nil
        }
    }
}

public extension Array {
    func chunked(_ size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

public extension Array where Element == String {
    func firstCaseInsensitive(_ stringToCompare: String) -> Element? {
        first(where: { $0.caseInsensitiveCompare(stringToCompare) == .orderedSame })
    }

    func containsCaseInsensitive(_ stringToCompare: String) -> Bool {
        contains(where: { $0.caseInsensitiveCompare(stringToCompare) == .orderedSame } )
    }
}

public extension Collection where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}
