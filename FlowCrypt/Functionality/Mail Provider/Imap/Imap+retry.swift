//
//  Imap+retry.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore

extension Imap {

    struct Null { }

    func execute<T_RES>(_ op: String, _ @escaping executor: (MCOIMAPSession, (Error?, T_RES?) -> Void) -> Void) async throws -> T_RES {
//        let start = DispatchTime.now()
        guard let imapSess = self.imapSess else {
            throw ImapError.noSession
        }
        do {
            let result = try await asAsync(imapSess, executor)
            lastErr.removeValue(forKey: op)
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

    private func asAsync<T_RES>(_ imapSess: MCOIMAPSession, _ executor: (MCOIMAPSession, (Error?, T_RES?) -> Void) -> Void) async throws -> T_RES {
        return try await withCheckedThrowingContinuation { continuation in
            executor(imapSess) { error, value in
                if let error = error {
                    return continuation.resume(throwing: error)
                } else if let value = value {
                    return continuation.resume(returning: value)
                } else if let null = Null() as? T_RES {
                    return continuation.resume(returning: null)
                } else {
                    return continuation.resume(throwing: AppErr.cast("Received nil from IMAP operation but was not cast as Null"))
                }
            }
        }
    }

    func shouldRetryOnce(_ op: String,_ appErr: AppErr) async throws -> Bool {
        switch appErr {
        case .authentication:
            try await renewSession() // todo - log time
            return true
        case .connection:
            // the connection has dropped, so it's probably ok to not officially "close" it. but maybe there could be a cleaner way to dispose of the connection?
            imapSess = nil
            smtpSess = nil
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
