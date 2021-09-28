//
//  PromiseExtensions.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

extension Promise {
    static func resolveAfter<T, E: Error>(timeout: TimeInterval = 0.2, with result: Result<T, E>) -> Promise<T> {
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

enum MockError: Error {
    case some
}
