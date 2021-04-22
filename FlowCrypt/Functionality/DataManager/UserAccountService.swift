//
//  UserAccountService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.02.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol UserAccountServiceType {
    func startSessionFor(user type: SessionType)
    func switchActiveSessionFor(user: User) -> SessionType?
    func startActiveSessionForNextUser() -> SessionType?
    func cleanup()
}

final class UserAccountService {
    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private let localStorage: LocalStorageType & LogOutHandler
    private let dataService: DataServiceType

    private let imap: Imap
    private let googleService: GoogleUserService

    init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage(),
        dataService: DataServiceType = DataService.shared,
        imap: Imap = .shared,
        googleService: GoogleUserService = GoogleUserService()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.dataService = dataService
        self.imap = imap
        self.googleService = googleService
    }

    private var currentUser: User? {
        dataService.currentUser
    }

    private var storages: [LogOutHandler] {
        [encryptedStorage, localStorage]
    }
}

extension UserAccountService: UserAccountServiceType {
    /// start session for a user, this method will log out current user if user was saved, save and start session for a new user
    func startSessionFor(user type: SessionType) {
        switch type {
        case let .google(email, name, token):
            // save new user data
            let user = UserObject.googleUser(
                name: name,
                email: email,
                token: token
            )
            encryptedStorage.saveActiveUser(with: user)
        case let .session(user):
            encryptedStorage.saveActiveUser(with: user)
            // start session for saved user
            imap.setupSession()
        }
    }

    func startActiveSessionForNextUser() -> SessionType? {
        logOutCurrentUser()

        guard let nextUser = encryptedStorage.getAllUsers().first else {
            return nil
        }

        let session = switchActiveSession(for: nextUser)

        return session
    }

    func switchActiveSessionFor(user: User) -> SessionType? {
        let userObj = self.encryptedStorage
            .getAllUsers()
            .first(where: { $0.email == user.email })

        guard let userObject = userObj else {
            debugPrint("[UserAccountService] UserObject should be persisted to encrypted storage")
            return nil
        }

        let session = switchActiveSession(for: userObject)

        return session
    }

    private func switchActiveSession(for userObject: UserObject) -> SessionType? {
        let sessionType: SessionType
        switch userObject.authType {
        case .oAuthGmail(let token):
            sessionType = .google(userObject.email, name: userObject.name, token: token)
        case .password:
            sessionType = .session(userObject)
        case .none:
            debugPrint("[UserAccountService] authType is not defined")
            return nil
        }

        startSessionFor(user: sessionType)

        return sessionType
    }

    private func logOutCurrentUser() {
        guard let email = dataService.currentUser?.email else {
            debugPrint("[UserAccountService] user is not logged in")
            return
        }

        switch dataService.currentAuthType {
        case .oAuthGmail:
            googleService.signOut(user: email)
        case .password:
            imap.disconnect()
        default:
            debugPrint("[UserAccountService] currentAuthType is not resolved")
        }

        do {
            try self.storages.forEach { try $0.logOutUser(email: email) }
        } catch let error {
            debugPrint("[UserAccountService] storage error \(error)")
        }
    }

    /// cleanup all user sessions
    func cleanup() {
        debugPrint("[UserAccountService] Clean up storages")
        encryptedStorage.cleanup()
        localStorage.cleanup()
    }
}
