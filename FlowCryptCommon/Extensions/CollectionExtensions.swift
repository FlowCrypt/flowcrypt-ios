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
        get {
            return indices.contains(index)
                ? self[index]
                : nil
        }
        set {
            if indices.contains(index), let newValue {
                self[index] = newValue
            }
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

public extension Array {
    mutating func safeRemove(at index: Int) {
        if !self.indices.contains(index) { return }
        self.remove(at: index)
    }
}

public extension [String] {
    func firstCaseInsensitive(_ stringToCompare: String) -> Element? {
        first(where: { $0.caseInsensitiveCompare(stringToCompare) == .orderedSame })
    }

    func containsCaseInsensitive(_ stringToCompare: String) -> Bool {
        contains(where: { $0.caseInsensitiveCompare(stringToCompare) == .orderedSame })
    }
}

public extension Collection where Element: Hashable {
    func unique() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
