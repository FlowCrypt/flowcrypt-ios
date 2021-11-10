//
//  UsersMailSessionProvider+Extensions.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 11/9/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

// MARK: - GmailService
extension GmailService: UsersMailSessionProvider {
    @discardableResult
    func renewSession() -> Promise<Void> {
        userService.renewSession()
    }
}
