//
//  Imap+session.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap {
    @discardableResult
    func getImapSess(newAccessToken: String? = nil) -> MCOIMAPSession {
        guard let existingImapSess = imapSess, newAccessToken == nil else {
            print("IMAP: creating a new session")
            let newImapSess = MCOIMAPSession()
            newImapSess.hostname = "imap.gmail.com"
            newImapSess.port = 993
            newImapSess.connectionType = MCOConnectionType.TLS
            newImapSess.authType = MCOAuthType.xoAuth2
            newImapSess.username = email
            newImapSess.password = nil
            newImapSess.oAuth2Token = newAccessToken ?? accessToken ?? "(no access token)"
            newImapSess.authType = MCOAuthType.xoAuth2
            newImapSess.connectionType = MCOConnectionType.TLS
//            newImapSess.connectionLogger = {(connectionID, type, data) in
//                if data != nil {
//                    if let string = String(data: data!, encoding: String.Encoding.utf8) {
//                        print("IMAP:\(type):\(string)")
//                    }
//                }
//            }
            imapSess = newImapSess
            return newImapSess
        }
        return existingImapSess
    }

    @discardableResult
    func getSmtpSess(newAccessToken: String? = nil) -> MCOSMTPSession {
        guard let existingSess = smtpSess, newAccessToken == nil else {
            print("SMTP: creating a new session")
            let newSmtpSess = MCOSMTPSession()
            newSmtpSess.hostname = "smtp.gmail.com"
            newSmtpSess.port = 465
            newSmtpSess.connectionType = MCOConnectionType.TLS
            newSmtpSess.authType = MCOAuthType.xoAuth2
            newSmtpSess.username = email
            newSmtpSess.password = nil
            newSmtpSess.oAuth2Token = newAccessToken ?? accessToken ?? "(no access token)"
            smtpSess = newSmtpSess
            return newSmtpSess
        }
        return existingSess
    }

    @discardableResult
    func renewSession() -> Promise<Void> {
//        Promise { resolve, reject in
            self.userService
                .renewAccessToken()
                .then { [weak self] token -> Void in
                    self?.getImapSess(newAccessToken: token)
                    self?.getSmtpSess(newAccessToken: token)
//                    resolve(())
                }
//            .catch { error in
//                    reject(error)
//                }
//        }
    }

    func disconnect() {
        let start = DispatchTime.now()
        imapSess?.disconnectOperation().start { error in log("disconnect", error: error, res: nil, start: start) }
        imapSess = nil
        smtpSess = nil // smtp session has no disconnect method
    }
}
