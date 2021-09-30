//
//  UserMailSessionProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

protocol UsersMailSessionProvider {
    func renewSession() -> Promise<Void>
}

// MARK: - GmailService
extension GmailService: UsersMailSessionProvider {
    @discardableResult
    func renewSession() -> Promise<Void> {
        userService.renewSession()
    }
}

// MARK: - Imap
extension Imap: UsersMailSessionProvider {
    @discardableResult
    func renewSession() -> Promise<Void> {
        Promise(self.setupSession())
    }
}
