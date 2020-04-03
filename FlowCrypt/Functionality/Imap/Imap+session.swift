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
    func setupSession() {
           createNewConnection(
               imapSession: dataService.imapSession(),
               smtpSession: dataService.smtpSession()
           )
       }

    private func createNewConnection(imapSession: IMAPSession?, smtpSession: SMTPSession?) {
        if let imap = imapSession {
            debugPrint("IMAP: creating a new session")
            let newImapSession = MCOIMAPSession(session: imap)
            imapSess = newImapSession
            logConnection(for: imapSess!)
        }

        if let smtp = smtpSession {
            debugPrint("SMTP: creating a new session")
            let newSmtpSession = MCOSMTPSession(session: smtp)
            smtpSess = newSmtpSession
        }
    }

    private func logConnection(for session: MCOIMAPSession) {
        session.connectionLogger = { (connectionID, type, data) in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            debugPrint("IMAP:\(type):\(string)")
        }
    }

    @discardableResult
    func renewSession() -> Promise<Void> {
        userService
            .renewSession()
            .then { [weak self] _ in
                self?.setupSession()
            }
    }

    func disconnect() {
        let start = DispatchTime.now()
        imapSess?.disconnectOperation().start { error in log("disconnect", error: error, res: nil, start: start) }
        imapSess = nil
        smtpSess = nil // smtp session has no disconnect method
    }
}
