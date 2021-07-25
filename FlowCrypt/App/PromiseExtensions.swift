//
//  PromiseExtensions.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Combine
import Foundation
import Promises

extension Promise {
    static func resolveAfter<T, E: Error>(timeout: TimeInterval = 5, with result: Result<T, E>) -> Promise<T> {
        Promise<T> { resolve, reject in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                switch result {
                case .success(let value):
                    resolve(value)
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }
}

extension Future {
    static func resolveAfter<T, E: Error>(timeout: TimeInterval = 5, with result: Result<T, E>) -> Future<T, E> {
        Future<T, E> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                promise(result)
            }
        }
    }
}

enum MockError: Error {
    case some
}
