//
//  UserAccountService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon

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
        case let .google(email, _, _):
            return email
        case let .session(user):
            return user.email
        }
    }
}

protocol SessionManagerType {
    func startSessionFor(session: SessionType) throws
    func switchActiveSessionFor(user: User) throws -> SessionType?
    func startActiveSessionForNextUser() throws -> SessionType?
    func cleanup() throws
    var currentSession: SessionType? { get }
}

final class SessionManager {
    private let encryptedStorage: EncryptedStorageType
    private let inMemoryPassPhraseStorage: PassPhraseStorageType
    private let localStorage: LocalStorageType

    private let imap: Imap
    private let googleAuthManager: GoogleAuthManager

    private lazy var logger = Logger.nested(Self.self)

    var currentSession: SessionType?

    init(
        encryptedStorage: EncryptedStorageType,
        inMemoryPassPhraseStorage: PassPhraseStorageType = InMemoryPassPhraseStorage(),
        localStorage: LocalStorageType = LocalStorage(),
        imap: Imap? = nil,
        googleAuthManager: GoogleAuthManager
    ) throws {
        self.googleAuthManager = googleAuthManager
        // todo - the following User.empty may be wrong - unsure, untested
        // maybe should instead get user
        self.imap = try imap ?? Imap(user: try encryptedStorage.activeUser ?? User.empty)
        self.encryptedStorage = encryptedStorage
        if let user = try encryptedStorage.activeUser, let authType = user.authType {
            switch authType {
            case let .oAuthGmail(token):
                currentSession = .google(user.email, name: user.name, token: token)
            case .password:
                currentSession = .session(user)
            }
        }
        self.localStorage = localStorage
        self.inMemoryPassPhraseStorage = inMemoryPassPhraseStorage
    }
}

extension SessionManager: SessionManagerType {
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

        guard let currentUser else {
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
        case let .oAuthGmail(token):
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
            googleAuthManager.signOut(user: user.email)
        case .password:
            try imap.disconnect()
        default:
            logger.logWarning("currentAuthType is not resolved")
        }
        do {
            try encryptedStorage.deleteAccount(email: user.email)
            try inMemoryPassPhraseStorage.removePassPhrases(for: user.email)
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
