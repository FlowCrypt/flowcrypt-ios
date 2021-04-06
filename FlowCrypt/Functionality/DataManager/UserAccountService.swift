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
    func logOutCurrentUser() -> Promise<Void>
    func startFor(user type: SessionType) -> Promise<SessionType>
    func switchActive(user: User) -> Promise<SessionType>
}

// TODO: - ANTON - handle errors
enum UserAccountServiceError: Error {
    case userIsNotLoggedIn
    case authTypeMissed
    case storage(Error)
    case internalError(String)
}

final class UserAccountService: UserAccountServiceType {
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

// MARK: - LogIn
extension UserAccountService {
    /// start session for a user, this method will log out current user if user was saved, save and start session for a new user
    func startFor(user type: SessionType) -> Promise<SessionType> {
        Promise<SessionType> { [weak self] (resolve, _) in
            guard let self = self else { throw AppErr.nilSelf }
            switch type {
            case let .google(email, name, token):
                // save new user data
                let user = UserObject.googleUser(
                    name: name,
                    email: email,
                    token: token
                )
                self.encryptedStorage.saveActiveUser(with: user)
                resolve(type)
            case let .session(user):
                self.encryptedStorage.saveActiveUser(with: user)
                // start session for saved user
                self.imap.setupSession()
                resolve(type)
            }
        }
    }

    func startForNextUserIfPossible() -> Promise<Void> {
        Promise { [weak self] (resolve, reject) in
            guard let user = self?.encryptedStorage.getAllUsers().first else {
               return resolve(())
            }

            // TODO: - ANTON
        }
    }

    func switchActive(user: User) -> Promise<SessionType> {
        Promise<SessionType> { [weak self] (resolve, reject) in
            guard let self = self else { throw AppErr.nilSelf }

            let userObj = self.encryptedStorage.getAllUsers()
                .first(where: { $0.email == user.email })

            guard let userObject = userObj else {
                throw UserAccountServiceError.internalError("UserObject should be persisted to encrypted storage")
            }

            let oldSessionType: SessionType
            switch userObject.authType {
            case .oAuthGmail, .none:
                guard let token = self.dataService.token else {
                    throw UserAccountServiceError.internalError("Token should be saved for this auth type")
                }
                oldSessionType = .google(user.email, name: user.name, token: token)
            case .password:
                oldSessionType = .session(userObject)
            }

            let newSession = try await(self.startFor(user: oldSessionType))

            resolve(newSession)
        }
    }
}

// MARK: - LogOut
extension UserAccountService {
    func logOutCurrentUser() -> Promise<Void> {
        Promise { [weak self] (resolve, reject) in
            guard let self = self else { throw AppErr.nilSelf }

            guard let currentUser = self.dataService.currentUser else {
                debugPrint("[UserAccountService] user is not logged in")
                return reject(UserAccountServiceError.userIsNotLoggedIn)
            }
            let email = currentUser.email

            switch self.dataService.currentAuthType {
            case .oAuthGmail:
                try await(self.logOutGmailSession())
            case .password:
                try await(self.logOutImapUserSession())
            default:
                reject(UserAccountServiceError.authTypeMissed)
            }

            do {
                try self.storages.forEach { try $0.logOutUser(email: email) }
                resolve(())
            } catch let error {
                reject(UserAccountServiceError.storage(error))
            }
        }
    }

    private func logOutGmailSession() -> Promise<Void> {
        googleService.signOut()
    }

    private func logOutImapUserSession() -> Promise<Void> {
        Promise<Void> { [weak self] (resolve, _) in
            self?.imap.disconnect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                resolve(())
            }
        }
    }
}
