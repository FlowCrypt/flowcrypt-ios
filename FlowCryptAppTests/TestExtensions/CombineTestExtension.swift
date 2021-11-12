//
//  CombineTestExtension.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 26.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import Foundation

extension Future {
    static func resolveAfter<T, E: Error>(timeout: TimeInterval = 5, with result: Result<T, E>) -> Future<T, E> {
        Future<T, E> { future in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                future(result)
            }
        }
    }
}
