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
        guard
            let imapSession = dataService.imapSession(),
            let smtpSession = dataService.smtpSession()
        else { return }

        createNewConnection(
            imapSession: imapSession,
            smtpSession: smtpSession
        )
    }

    private func createNewConnection(imapSession: IMAPSession?, smtpSession: SMTPSession?) {
        if let imap = imapSession {
            debugPrint("IMAP: creating a new session")
            let newImapSession = MCOIMAPSession(session: imap)
            imapSess = newImapSession
            //logIMAPConnection(for: imapSess!)
        }

        if let smtp = smtpSession {
            debugPrint("SMTP: creating a new session")
            let newSmtpSession = MCOSMTPSession(session: smtp)
            smtpSess = newSmtpSession
            //logSMTPConnection(for: smtpSess!)
        }
    }

    private func logIMAPConnection(for session: MCOIMAPSession) {
        session.connectionLogger = { (connectionID, type, data) in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            debugPrint("### IMAP:\(type):\(string)")
        }
    }

    private func logSMTPConnection(for smtpSession: MCOSMTPSession) {
        smtpSession.connectionLogger = { (connectionID, type, data) in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            debugPrint("### SMTP:\(type):\(string)")
        }
    }

    func connectSmtp(session: SMTPSession) -> Promise<Void> {
        Promise { resolve, reject in
            MCOSMTPSession(session: session)
                .loginOperation()?
                .start { error in
                    guard let error = error else { resolve(()); return }
                    reject(AppErr.unexpected("Can't establish SMTP Connection.\n\(error.localizedDescription)"))
                }
        }
    }

    func connectImap(session: IMAPSession) -> Promise<Void> {
         Promise { resolve, reject in
            MCOIMAPSession(session: session)
                .connectOperation()?
                .start { error in
                    guard let error = error else { resolve(()); return }
                    reject(AppErr.unexpected("Can't establish IMAP Connection.\n\(error.localizedDescription)"))
                }
        }
    }

    func disconnect() {
        let start = DispatchTime.now()
        imapSess?.disconnectOperation().start { error in
//            log("disconnect", error: error, res: nil, start: start)
        }
        imapSess = nil
        smtpSess = nil // smtp session has no disconnect method
    }
}
