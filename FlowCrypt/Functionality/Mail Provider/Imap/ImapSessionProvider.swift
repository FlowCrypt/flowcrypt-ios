//
//  ImapSessionProvider.swift
//  FlowCrypt
//
//  Created by Tom on 30.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol ImapSessionProviderType {
    func imapSession() throws -> IMAPSession
    func smtpSession() throws -> SMTPSession
}

class ImapSessionProvider: ImapSessionProviderType {

    private let user: User

    init(user: User) {
        self.user = user
    }

    func imapSession() throws -> IMAPSession {
        return try IMAPSession(user: self.user)
    }

    func smtpSession() throws -> SMTPSession {
        return try SMTPSession(user: self.user)
    }
}
