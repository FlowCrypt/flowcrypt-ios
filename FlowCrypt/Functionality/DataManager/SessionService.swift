//
//  UserAccountService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

enum SessionType: CustomStringConvertible {
    case google(_ email: String, name: String, token: String)
    case session(_ user: User)

    var description: String {
        switch self {
        case let .google(email, name, _):
            return "Google \(email) \(name)"
        case let .session(user):
            return "Session \(user.email)"
        }
    }

    var email: String {
        switch self {
        case .google(let email, _, _):
            return email
        case .session(let user):
            return user.email
        }
    }
}

protocol SessionServiceType {
    func startSessionFor(session: SessionType) throws
    func switchActiveSessionFor(user: User) throws -> SessionType?
    func startActiveSessionForNextUser() throws -> SessionType?
    func cleanup() throws
}

final class SessionService {
    private let encryptedStorage: EncryptedStorageType
    private let passPhraseStorage: PassPhraseStorageType
    private let localStorage: LocalStorageType

    private let imap: Imap
    private let googleService: GoogleUserService

    private lazy var logger = Logger.nested(Self.self)

    init(
        encryptedStorage: EncryptedStorageType,
        passPhraseStorage: PassPhraseStorageType = InMemoryPassPhraseStorage(),
        localStorage: LocalStorageType = LocalStorage(),
        imap: Imap? = nil,
        googleService: GoogleUserService
    ) throws {
        self.googleService = googleService
        // todo - the following User.empty may be wrong - unsure, untested
        // maybe should instead get user
        self.imap = try imap ?? Imap(user: try encryptedStorage.activeUser ?? User.empty)
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.passPhraseStorage = passPhraseStorage
    }
}

extension SessionService: SessionServiceType {
    /// start session for a user, this method will log out current user if user was saved, save and start session for a new user
    func startSessionFor(session: SessionType) throws {
        switch session {
        case let .google(email, name, token):
            let user = User.googleUser(
                name: name,
                email: email,
                token: token
            )
            try encryptedStorage.saveActiveUser(with: user)
        case let .session(user):
            try imap.setupSession()
            try encryptedStorage.saveActiveUser(with: user)
        }
    }

    func startActiveSessionForNextUser() throws -> SessionType? {
        guard let currentUser = try encryptedStorage.activeUser else {
            return nil
        }
        try logOut(user: currentUser)

        guard let nextUser = try encryptedStorage.getAllUsers().first else {
            return nil
        }

        let session = try switchActiveSession(for: nextUser)

        return session
    }

    func switchActiveSessionFor(user: User) throws -> SessionType? {
        let currentUser = try encryptedStorage
            .getAllUsers()
            .first(where: { $0.email == user.email })

        guard let currentUser = currentUser else {
            logger.logWarning("UserObject should be persisted to encrypted storage in case of switching accounts")
            return nil
        }

        return try switchActiveSession(for: currentUser)
    }

    @discardableResult
    private func switchActiveSession(for user: User) throws -> SessionType? {
        logger.logInfo("Try to switch session for \(user.email)")

        let sessionType: SessionType
        switch user.authType {
        case .oAuthGmail(let token):
            sessionType = .google(user.email, name: user.name, token: token)
        case .password:
            sessionType = .session(user)
        case .none:
            logger.logWarning("authType is not defined in switchActiveSession")
            return nil
        }

        try startSessionFor(session: sessionType)

        return sessionType
    }

    private func logOut(user: User) throws {
        logger.logInfo("Logging out user \(user.email)")
        switch user.authType {
        case .oAuthGmail:
            googleService.signOut(user: user.email)
        case .password:
            try imap.disconnect()
        default:
            logger.logWarning("currentAuthType is not resolved")
        }
        do {
            try encryptedStorage.deleteAccount(email: user.email)
            try passPhraseStorage.removePassPhrases(for: user.email)
            localStorage.cleanup()
        } catch {
            logger.logError("storage error \(error)")
        }
    }

    /// cleanup all user sessions
    func cleanup() throws {
        logger.logInfo("Clean up storages")
        try encryptedStorage.cleanup()
        localStorage.cleanup()
    }
}
