//
//  Imap+retry.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap {

    func finalize<T>(
        _ op: String,
        _ resolve: @escaping (T) -> Void,
        _ reject: @escaping (Error) -> Void,
        retry: @escaping () -> Promise<T>
    ) -> (Error?, T?) -> Void {
        let start = DispatchTime.now()
        return { [weak self] (error, res) in
            log(op, error: error, res: res, start: start)
            guard self?.retryAuthErrorNotNeeded(op, error, resolve, reject, retry: retry) ?? false else { return }
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
            log(op, error: error, res: nil, start: start)
            guard self?.retryAuthErrorNotNeeded(op, error, resolve, reject, retry: retry) ?? false else { return }

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
        return { [weak self] (error, discardable) in
            log(op, error: error, res: nil, start: start)
            guard self?.retryAuthErrorNotNeeded(op, error, resolve, reject, retry: retry) ?? false else { return }
            if let error = error {
                reject(error)
            } else {
                resolve(())
            }
        }
    }

    /// must be always called with `guard retryAuthErrorNotNeeded else { return }`
    func retryAuthErrorNotNeeded<T>(
        _ op: String,
        _ err: Error?,
        _ resolve: @escaping (T) -> Void,
        _ reject: @escaping (Error) -> Void,
        retry: @escaping () -> Promise<T>
    ) -> Bool {
        if let err = err {
            let error = AppErr(err)
            let debugId = Int.random(in: 1...Int.max)
            let start = DispatchTime.now()

            switch error {
            case .authentication:
                if let operation = lastErr[op], operation == error { return true }
                logDebug(3, "(\(debugId)|\(op)) it's a retriable auth err, will call renewAccessToken")
                lastErr[op] = error

                renewSession().then { _ in
                    logDebug(5, "(\(debugId)|\(op)) forced session refreshes")
                    log("renewAccessToken for \(op), will retry \(op)", error: nil, res: "<accessToken>", start: start)
                    retry().then(resolve).catch(reject)
                }.catch(reject)
                logDebug(7, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
                logDebug(11, "(\(debugId)|\(op)) return=true (need to retry)")

                return false
            case .connection:
                if let operation = lastErr[op], operation == error { return true }
                logDebug(13, "(\(debugId)|\(op)) it's a retriable conn err, clear sessions")

                imapSess = nil // the connection has dropped, so it's probably ok to not officially "close" it
                smtpSess = nil // but maybe there could be a cleaner way to dispose of the connection?
                lastErr[op] = error

                logDebug(14, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
                log("conn drop for \(op), cleared sessions, will retry \(op)", error: nil, res: nil, start: start)
                retry().then(resolve).catch(reject)
                logDebug(15, "(\(debugId)|\(op)) return=true (need to retry)")
                return false
            default:
                logDebug(8, "(\(debugId)|\(op)) err not retriable, rejecting ", value: err)
                reject(error)
                self.lastErr[op] = error
                logDebug(9, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
                logDebug(12, "(\(debugId)|\(op)) return=true (no need to retry)")
                return true
            }
        } else {
            lastErr.removeValue(forKey: op)
            return true
        }
    }
}
