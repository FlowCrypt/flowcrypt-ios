//
//  Temporarry.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/29/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

// TODO: - Draft
// Implement retryable

func shouldRetry(on error: Error?, title: String?) -> Bool {
    guard let error = error else { return false }

    let debugId = UUID()

    let title = title ?? ""
    Logger.debug(1, "(\(debugId)|\(title)) on error = ", value: error)

    let flowCryptEroor = FCError(error)
    Logger.debug(2, "(\(debugId)|\(title)) error type =", value: flowCryptEroor)

    switch flowCryptEroor {
    case .authentication: break
    case .general: break
    case .operation: break
    }
    return false
}

func handleAuthError() {

    // GoogleApi.shared.renewAccessToken()

    //    self.googleApi.renewAccessToken().then { accessToken in
    //        Imap.debug(4, "(\(debugId)|\(op)) got renewed access token")
    //        let _ = self.getImapSess(newAccessToken: accessToken) // use the new token
    //        let _ = self.getSmtpSess(newAccessToken: accessToken) // use the new token
    //        Imap.debug(5, "(\(debugId)|\(op)) forced session refreshes")
    //        self.logger.log("renewAccessToken for \(op), will retry \(op)", error: nil, res: "<accessToken>", start: start)
    //        retry().then(resolve).catch(reject)
    //        }.catch { error in
    //            Imap.debug(6, "(\(debugId)|\(op)) error refreshing token", value: e)
    //            self.logger.log("renewAccessToken for \(op)", error: error, res: nil, start: start)
    //            reject(error)
    //    }
    //    self.lastErr[op] = Err(rawValue: e.code)
    //    Imap.debug(7, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
    //    Imap.debug(11, "(\(debugId)|\(op)) return=true (need to retry)")
    //    return false; // need to retry
}
//
//        let start = DispatchTime.now()
//        // also checking against lastErr below to avoid infinite retry loop
//        if let e = err as NSError?, e.code == Err.authentication.rawValue, self.lastErr[op] != Err.authentication {
//
//        } else if let e = err as NSError?, e.code == Err.connection.rawValue, self.lastErr[op] != Err.connection {
//            Imap.debug(13, "(\(debugId)|\(op)) it's a retriable conn err, clear sessions")
//            self.imapSess = nil; // the connection has dropped, so it's probably ok to not officially "close" it
//            self.smtpSess = nil; // but maybe there could be a cleaner way to dispose of the connection?
//            self.lastErr[op] = Err(rawValue: e.code)
//            Imap.debug(14, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
//            self.logger.log("conn drop for \(op), cleared sessions, will retry \(op)", error: nil, res: nil, start: start)
//            retry().then(resolve).catch(reject)
//            Imap.debug(15, "(\(debugId)|\(op)) return=true (need to retry)")
//            return false; // need to retry
//        } else {
//            Imap.debug(8, "(\(debugId)|\(op)) err not retriable, rejecting ", value: err)
//            reject(err ?? ImapError.general)
//            self.lastErr[op] = Err(rawValue: (err as NSError?)?.code ?? Constants.Global.generalError)
//            Imap.debug(9, "(\(debugId)|\(op)) just set lastErr to ", value: self.lastErr[op])
//            Imap.debug(12, "(\(debugId)|\(op)) return=true (no need to retry)")
//            return true // no need to retry
//        }
//}
