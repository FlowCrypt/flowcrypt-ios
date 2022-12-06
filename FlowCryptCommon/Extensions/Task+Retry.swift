//
//  Task+Retry.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 3/30/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

enum GmailApiError: Error {
    /// Invalid auth grant
    case invalidGrant(Error)
}

public extension Task where Failure == Error {
    @discardableResult
    static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = 2,
        retryDelayMs: UInt64 = 1000,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for _ in 0 ..< maxRetryCount {
                do {
                    return try await operation()
                } catch {
                    switch error {
                    case GmailApiError.invalidGrant:
                        // valid grant is needed before retry
                        throw error
                    default:
                        let oneMillisecond = UInt64(1_000_000)
                        let delay = oneMillisecond * retryDelayMs
                        try await Task<Never, Never>.sleep(nanoseconds: delay)
                    }
                }
            }

            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
}
