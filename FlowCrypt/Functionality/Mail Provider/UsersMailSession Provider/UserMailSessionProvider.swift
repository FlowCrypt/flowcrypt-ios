//
//  UserMailSessionProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

protocol UsersMailSessionProvider {
    func renewSession() async throws
}

// MARK: - GmailService
extension GmailService: UsersMailSessionProvider {
    func renewSession() async throws {
        try await googleAuthManager.renewSession()
    }
}

// MARK: - Imap
extension Imap: UsersMailSessionProvider {
    func renewSession() async throws {
        try setupSession()
    }
}
