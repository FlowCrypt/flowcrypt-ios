//
//  CombineExtensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import Foundation

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
}

extension Publishers.SubscribeOn {
    // swiftlint:disable line_length
    func myFlatMap<P>(_ transform: @escaping (Self.Output) -> P) -> Publishers.FlatMap<P, Publishers.SetFailureType<Self, P.Failure>> where P: Publisher {
        Publishers.FlatMap<P, Publishers.SetFailureType<Self, P.Failure>>(
            upstream: Publishers.SetFailureType<Self, P.Failure>(upstream: self),
            maxPublishers: .unlimited,
            transform: transform
        )
    }
}
