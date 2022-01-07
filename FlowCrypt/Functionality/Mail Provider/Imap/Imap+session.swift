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
        guard let imapSession = imapSess, let smtpSession = smtpSess else {
            logger.logError("No IMAP session")
            return
        }
        imapSession.startLogging()
        smtpSession.startLogging()
    }

    func connectSmtp(session: SMTPSession) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            MCOSMTPSession(session: session)
                .startLogging()
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
                .startLogging()
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
    }
}

extension MCOIMAPSession {
    @discardableResult
    func startLogging() -> Self {
        connectionLogger = { _, type, data in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            Logger.nested("IMAP").logInfo("\(type):\(string)")
        }
        return self
    }
}

extension MCOSMTPSession {
    @discardableResult
    func startLogging() -> Self {
        connectionLogger = { _, type, data in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            Logger.nested("SMTP").logInfo("\(type):\(string)")
        }
        return self
    }
}
