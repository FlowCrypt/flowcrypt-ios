//
//  CombineTestExtension.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 26.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Combine

extension Future {
    static func resolveAfter<T, E: Error>(timeout: TimeInterval = 5, with result: Result<T, E>) -> Future<T, E> {
        Future<T, E> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                promise(result)
            }
        }
    }
}
