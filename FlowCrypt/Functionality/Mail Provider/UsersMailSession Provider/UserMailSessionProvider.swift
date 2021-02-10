//
//  UserMailSessionProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.02.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises

protocol UsersMailSessionProvider {
    func renewSession() -> Promise<Void>
}

extension GmailService: UsersMailSessionProvider {
    @discardableResult
    func renewSession() -> Promise<Void> {
        userService.renewSession()
    }
}

extension Imap: UsersMailSessionProvider {
    @discardableResult
    func renewSession() -> Promise<Void> {
        Promise(self.setupSession())
    }
}
