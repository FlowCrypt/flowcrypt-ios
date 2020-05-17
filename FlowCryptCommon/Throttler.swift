//
//  Throttler.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 28/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

public final class Throttler {
    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)

    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: Int

    public init(seconds: Int) {
        maxInterval = seconds
    }

    public func throttle(_ block: @escaping () -> Void) {
        job.cancel()
        job = DispatchWorkItem { [weak self] in
            self?.previousRun = Date()
            block()
        }
        let delay = Date.second(from: previousRun) > maxInterval
            ? 0
            : maxInterval

        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> Int {
        return Int(Date().timeIntervalSince(referenceDate).rounded())
    }
}
