//
//  SequenceExtension.swift
//  FlowCryptCommon
//
//  Created by Ioan Moldovan on 1/23/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

public extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
