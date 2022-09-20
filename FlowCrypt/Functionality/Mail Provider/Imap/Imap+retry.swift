//
//  Imap+retry.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

extension Imap {

    func executeVoid(
        _ op: String,
        _ voidExecutor: @escaping (MCOIMAPSession, @escaping (Error?) -> Void) -> Void
    ) async throws {
        do {
            let imapSess = try self.imapSess
            try await asAsync(imapSess, voidExecutor)
            // todo - log time
            return
        } catch {
            // todo - log error + time
            if try await shouldRetryOnce(op, AppErr(error)) == false {
                throw error
            } else {
                do {
                    try await asAsync(imapSess, voidExecutor)
                    // todo - log time
                    return
                } catch {
                    // log this error + time
                    throw error
                }
            }
        }
    }

    func execute<RES>(
        _ op: String,
        _ executor: @escaping (MCOIMAPSession, @escaping (Error?, RES?) -> Void) -> Void
    ) async throws -> RES {
//        let start = DispatchTime.now()
        do {
            let imapSess = try self.imapSess
            let result = try await asAsync(imapSess, executor)
            // todo - log result + time
            return result
        } catch {
            // todo - log error + time
            if try await shouldRetryOnce(op, AppErr(error)) == false {
                throw error
            } else {
                do {
                    let result = try await asAsync(imapSess, executor)
                    // todo - log result + time
                    return result
                } catch {
                    // log this error + time
                    throw error
                }
            }
        }
    }

    private func asAsync<RES>(
        _ imapSess: MCOIMAPSession,
        _ executor: @escaping (MCOIMAPSession, @escaping (Error?, RES?) -> Void) -> Void
    ) async throws -> RES {
        return try await withCheckedThrowingContinuation { continuation in
            executor(imapSess) { error, value in
                if let error = error {
                    return continuation.resume(throwing: error)
                } else if let value = value {
                    return continuation.resume(returning: value)
                } else {
                    return continuation.resume(throwing: AppErr.cast("Received nil from IMAP operation"))
                }
            }
        }
    }

    private func asAsync(
        _ imapSess: MCOIMAPSession,
        _ executor: @escaping (MCOIMAPSession, @escaping (Error?) -> Void) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            executor(imapSess) { error in
                if let error = error {
                    return continuation.resume(throwing: error)
                } else {
                    return continuation.resume()
                }
            }
        }
    }

    func shouldRetryOnce(
        _ op: String,
        _ appErr: AppErr
    ) async throws -> Bool {
        switch appErr {
        case .authentication:
            try await renewSession() // todo - log time
            return true
        case .connection:
            // the connection has dropped, so it's probably ok to not officially "close" it.
            // but maybe there could be a cleaner way to dispose of the connection?
            // imapSess = nil
            // smtpSess = nil
            // this is a mess, neads a real refactor. use DI
            // todo - for now renewing of session disabled, will probably break retries
//            setupSession()
//            await connectImap(session: imapSessNotNil)
            return true
        default:
            return false
        }
    }
}
