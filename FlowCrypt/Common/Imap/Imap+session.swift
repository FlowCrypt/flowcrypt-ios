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
    func getImapSess(newAccessToken: String? = nil) -> MCOIMAPSession? {
        if imapSess == nil || newAccessToken != nil {
            print("IMAP: creating a new session")
            let imapSess = MCOIMAPSession()
            imapSess.hostname = "imap.gmail.com"
            imapSess.port = 993
            imapSess.connectionType = MCOConnectionType.TLS
            imapSess.authType = MCOAuthType.xoAuth2
            imapSess.username = email
            imapSess.password = nil
            imapSess.oAuth2Token = newAccessToken ?? DataManager.shared.currentToken() ?? ""
            imapSess.authType = MCOAuthType.xoAuth2
            imapSess.connectionType = MCOConnectionType.TLS
            self.imapSess = imapSess
            //            imapSess.connectionLogger = {(connectionID, type, data) in
            //                if data != nil {
            //                    if let string = String(data: data!, encoding: String.Encoding.utf8) {
            //                        print("IMAP:\(type):\(string)")
            //                    }
            //                }
            //            }
        }
        return imapSess
    }

    @discardableResult
    func getSmtpSess(newAccessToken: String? = nil) -> MCOSMTPSession? {
        if smtpSess == nil || newAccessToken != nil {
            print("SMTP: creating a new session")
            let smtpSess = MCOSMTPSession()
            smtpSess.hostname = "smtp.gmail.com"
            smtpSess.port = 465
            smtpSess.connectionType = MCOConnectionType.TLS
            smtpSess.authType = MCOAuthType.xoAuth2
            smtpSess.username = email
            smtpSess.password = nil
            smtpSess.oAuth2Token = token
            self.smtpSess = smtpSess
        }
        return smtpSess
    }

    func renewSession() -> Promise<VOID> {
        return userService
            .renewAccessToken()
            .then { [weak self] token in
                self?.getImapSess(newAccessToken: token)
                self?.getSmtpSess(newAccessToken: token)
                return Promise(VOID())
        }
    }

    func disconnect() {
        let start = DispatchTime.now()
        self.imapSess?.disconnectOperation().start { error in log("disconnect", error: error, res: nil, start: start) }
        self.imapSess = nil
        self.smtpSess = nil // smtp session has no disconnect method
    }
}
