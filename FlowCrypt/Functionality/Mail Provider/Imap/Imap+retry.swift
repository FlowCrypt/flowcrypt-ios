//
//  Imap+retry.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

extension Imap {
    func finalize<T>(
        _ op: String,
        _ resolve: @escaping (T) -> Void,
        _ reject: @escaping (Error) -> Void,
        retry: @escaping () -> Promise<T>,
        start: DispatchTime = DispatchTime.now()
    ) -> (Error?, T?) -> Void {
        { [weak self] error, res in
            self?.logger.logError("Error \(String(describing: error))")
//            log(op, error: error, res: res, start: start)
            guard self?.notRetrying(op, error, resolve, reject, retry: retry) ?? false else { return }
            if let res = res {
                resolve(res)
            } else {
                reject(error ?? AppErr.unexpected("Error is empty, but no result"))
            }
        }
    }

    func finalizeVoid(
        _ op: String,
        _ resolve: @escaping (Void) -> Void, // needed for Swift4 Promises compatibility
        _ reject: @escaping (Error) -> Void,
        retry: @escaping () -> Promise<Void>
    ) -> (Error?) -> Void {
        let start = DispatchTime.now()
        return { [weak self] error in
            self?.logger.logError("Error \(String(describing: error))")
            guard self?.notRetrying(op, error, resolve, reject, retry: retry) ?? false else { return }

            if let error = error {
                reject(error)
            } else {
                resolve(())
            }
        }
    }

    func finalizeAsVoid(
        _ op: String,
        _ resolve: @escaping (Void) -> Void, // needed for Swift4 Promises compatibility
        _ reject: @escaping (Error) -> Void,
        retry: @escaping () -> Promise<Void>
    ) -> (Error?, Any?) -> Void {
        let start = DispatchTime.now()
        return { [weak self] error, _ in
            self?.logger.logError("Error \(String(describing: error))")
            guard self?.notRetrying(op, error, resolve, reject, retry: retry) ?? false else { return }
            if let error = error {
                reject(error)
            } else {
                resolve(())
            }
        }
    }

    /// must be always called with `guard retryAuthErrorNotNeeded else { return }`
    func notRetrying<T>(
        _ op: String,
        _ err: Error?,
        _ resolve: @escaping (T) -> Void,
        _ reject: @escaping (Error) -> Void,
        retry: @escaping () -> Promise<T>
    ) -> Bool {
        if let err = err {
            let error = AppErr(err)
            // let debugId = Int.random(in: 1 ... Int.max)
            // let start = DispatchTime.now()

            switch error {
            case .authentication:
                if let operation = lastErr[op], operation == error { return true }
//                logger.logInfo("it's a retriable auth err, will call renewAccessToken \(op)")
                lastErr[op] = error

                renewSession()
                    .then { _ in
//                        self?.logger.logInfo("forced session refreshes \(op)")
                        retry().then(resolve).catch(reject)
                    }
                    .catch(reject)
//                logger.logDebug("just set lastErr to \(lastErr[op])")

                return false
            case .connection:
                if let operation = lastErr[op], operation == error { return true }
//                logDebug(13, "(\(debugId)|\(op)) it's a retriable conn err, clear sessions")

                imapSess = nil // the connection has dropped, so it's probably ok to not officially "close" it
                smtpSess = nil // but maybe there could be a cleaner way to dispose of the connection?
                lastErr[op] = error

//                logDebug(14, "(\(debugId)|\(op)) just set lastErr to ", value: lastErr[op])
//                log("conn drop for \(op), cleared sessions, will retry \(op)", error: nil, res: nil, start: start)
                retry().then(resolve).catch(reject)
//                logDebug(15, "(\(debugId)|\(op)) return=true (need to retry)")
                return false
            default:
//                logDebug(8, "(\(debugId)|\(op)) err not retriable, rejecting ", value: err)
                reject(error)
                lastErr[op] = error
//                logDebug(9, "(\(debugId)|\(op)) just set lastErr to ", value: lastErr[op])
//                logDebug(12, "(\(debugId)|\(op)) return=true (no need to retry)")
                return true
            }
        } else {
            lastErr.removeValue(forKey: op)
            return true
        }
    }
}
