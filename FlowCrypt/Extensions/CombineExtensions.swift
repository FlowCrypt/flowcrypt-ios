//
//  CombineExtensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import Foundation
import RealmSwift

extension Publisher {
    /// Attaches a subscriber with closure-based behaviour which will emit value and error
    func sinkFuture(receiveValue: @escaping (Output) -> Void, receiveError: @escaping (Self.Failure) -> Void) -> AnyCancellable {
        self.sink(
            receiveCompletion: { result in
                guard case .failure(let error) = result else {
                    return
                }

                receiveError(error)
            },
            receiveValue: { value in
                receiveValue(value)
            })
    }

    func wait() {
        let semaphore = DispatchSemaphore(value: 0)
        _ = sinkFuture { _ in
            semaphore.signal()
        } receiveError: { _ in
            semaphore.signal()
        }
        semaphore.wait()
    }
}
