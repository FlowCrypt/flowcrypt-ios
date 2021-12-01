//
//  UserAccountService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

protocol SessionServiceType {
    func startSessionFor(session: SessionType)
    func switchActiveSessionFor(user: User) -> SessionType?
    func startActiveSessionForNextUser() -> SessionType?
    func cleanupSessions()
    func cleanup()
}

final class SessionService {
    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private let localStorage: LocalStorageType & LogOutHandler

    private let imap: Imap
    private let googleService: GoogleUserService
    private let dataService: DataService

    private lazy var logger = Logger.nested(Self.self)

    init(
        encryptedStorage: EncryptedStorageType & LogOutHandler,
        localStorage: LocalStorageType & LogOutHandler = LocalStorage(),
        dataService: DataService,
        imap: Imap? = nil,
        googleService: GoogleUserService
    ) {
        self.googleService = googleService
        // todo - the following User.empty may be wrong - unsure, untested
        // maybe should instead get user
        self.imap = imap ?? Imap(user: dataService.currentUser ?? User.empty)
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.dataService = dataService
    }

    private var storages: [LogOutHandler] {
        [encryptedStorage, localStorage]
    }
}

extension SessionService: SessionServiceType {
    /// start session for a user, this method will log out current user if user was saved, save and start session for a new user
    func startSessionFor(session: SessionType) {
        switch session {
        case let .google(email, name, token):
            let user = User.googleUser(
                name: name,
                email: email,
                token: token
            )
            encryptedStorage.saveActiveUser(with: user)
        case let .session(user):
            imap.setupSession()
            encryptedStorage.saveActiveUser(with: user)
        }
    }

    func startActiveSessionForNextUser() -> SessionType? {
        guard let currentUser = dataService.currentUser else {
            return nil
        }
        logOut(user: currentUser)

        guard let nextUser = encryptedStorage.getAllUsers().first else {
            return nil
        }

        let session = switchActiveSession(for: nextUser)

        return session
    }

    func switchActiveSessionFor(user: User) -> SessionType? {
        let currentUser = encryptedStorage
            .getAllUsers()
            .first(where: { $0.email == user.email })

        guard let currentUser = currentUser else {
            logger.logWarning("UserObject should be persisted to encrypted storage in case of switching accounts")
            return nil
        }

        return switchActiveSession(for: currentUser)
    }

    // todo - rename to "logOutUsersThatDontHaveAnyKeysSetUp"
    func cleanupSessions() {
        logger.logInfo("Clean up sessions")
        for user in encryptedStorage.getAllUsers() {
            if !encryptedStorage.doesAnyKeyExist(for: user.email) {
                logger.logInfo("User session to clean up \(user.email)")
                logOut(user: user)
            }
        }
        let users = encryptedStorage.getAllUsers()
        if !users.contains(where: { $0.isActive }), let user = users.first(where: { encryptedStorage.doesAnyKeyExist(for: $0.email ) }) {
            switchActiveSession(for: user)
        }
    }

    @discardableResult
    private func switchActiveSession(for user: User) -> SessionType? {
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

        startSessionFor(session: sessionType)

        return sessionType
    }

    private func logOut(user: User) {
        logger.logInfo("Logging out user \(user.email)")
        switch user.authType {
        case .oAuthGmail:
            googleService.signOut(user: user.email)
        case .password:
            imap.disconnect()
        default:
            logger.logWarning("currentAuthType is not resolved")
        }
        do {
            for storage in self.storages {
                try storage.logOutUser(email: user.email)
            }
        } catch {
            logger.logError("storage error \(error)")
        }
    }

    /// cleanup all user sessions
    func cleanup() {
        logger.logInfo("Clean up storages")
        encryptedStorage.cleanup()
        localStorage.cleanup()
    }
}
