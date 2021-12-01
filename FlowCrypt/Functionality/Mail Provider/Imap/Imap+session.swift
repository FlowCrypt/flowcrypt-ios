//
//  Imap+session.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import MailCore

extension Imap {

    func setupSession() {
        guard
            let imapSession = imapSessionProvider.imapSession(),
            let smtpSession = imapSessionProvider.smtpSession()
        else { return }
        logger.logInfo("Creating a new IMAP session")
        let newImapSession = MCOIMAPSession(session: imapSession)
        imapSess = newImapSession.log()
        logger.logInfo("Creating a new SMTP session")
        let newSmtpSession = MCOSMTPSession(session: smtpSession)
        smtpSess = newSmtpSession.log()
    }

    func connectSmtp(session: SMTPSession) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            MCOSMTPSession(session: session)
                .log()
                .loginOperation()?
                .start { error in
                    if let error = error {
                        return continuation.resume(throwing: error)
                    } else {
                        return continuation.resume()
                    }
                }
        }
    }

    func connectImap(session: IMAPSession) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            MCOIMAPSession(session: session)
                .log()
                .connectOperation()?
                .start { error in
                    if let error = error {
                        return continuation.resume(throwing: error)
                    } else {
                        return continuation.resume()
                    }
                }
        }
    }

    func disconnect() {
        let start = Trace(id: "Imap disconnect")
        imapSess?.disconnectOperation().start { [weak self] error in
            if let error = error {
                self?.logger.logError("disconnect with \(error)")
            } else {
                self?.logger.logInfo("disconnect with duration \(start.finish())")
            }
        }
        imapSess = nil
        smtpSess = nil // smtp session has no disconnect method
    }
}

extension MCOIMAPSession {
    func log() -> Self {
        connectionLogger = { _, type, data in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            Logger.nested("IMAP").logInfo("\(type):\(string)")
        }
        return self
    }
}

extension MCOSMTPSession {
    func log() -> Self {
        connectionLogger = { _, type, data in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            Logger.nested("SMTP").logInfo("\(type):\(string)")
        }
        return self
    }
}
