//
//  OptionalExtensions.swift
//  FlowCryptCommon
//
//  Created by Ioan Moldovan on 5/5/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public extension Optional {
    func ifNotNil<U>(_ transform: (Wrapped) throws -> U) rethrows -> U? {
        switch self {
        case .some(let value):
          return .some(try transform(value))
        case .none:
          return .none
        }
    }
}

public extension Optional where Wrapped: Collection {
    var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}
