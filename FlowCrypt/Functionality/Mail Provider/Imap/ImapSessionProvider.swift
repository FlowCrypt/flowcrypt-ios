//
//  ImapSessionProvider.swift
//  FlowCrypt
//
//  Created by Tom on 30.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol ImapSessionProviderType {
    func imapSession() -> IMAPSession?
    func smtpSession() -> SMTPSession?
}

class ImapSessionProvider: ImapSessionProviderType {

    private let user: User

    init(user: User) {
        self.user = user
    }

    func imapSession() -> IMAPSession? {
        guard let imapSession = IMAPSession(user: self.user) else {
            assertionFailure("couldn't create IMAP Session with this parameters")
            return nil
        }
        return imapSession
    }

    func smtpSession() -> SMTPSession? {
        guard let smtpSession = SMTPSession(user: self.user) else {
            assertionFailure("couldn't create SMTP Session with this parameters")
            return nil
        }
        return smtpSession
    }
}
