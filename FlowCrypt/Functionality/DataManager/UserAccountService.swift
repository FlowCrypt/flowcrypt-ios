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
    func startFor(user type: SessionType) -> Promise<Void>
}

// TODO: - ANTON - handle errors
enum UserAccountServiceError: Error {
    case userIsNotLoggedIn
    case storage(Error)
}

final class UserAccountService: UserAccountServiceType {
    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private let localStorage: LocalStorageType & LogOutHandler
    private let dataService: DataServiceType

    private let imap: Imap

    init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage(),
        dataService: DataServiceType = DataService.shared,
        imap: Imap = .shared
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.dataService = dataService
        self.imap = imap
    }

    private var currentUser: User? {
        dataService.currentUser
    }

    private var storages: [LogOutHandler] {
        [encryptedStorage, localStorage]
    }
}

// MARK: - LogOut
extension UserAccountService {
    func logOutCurrentUser() -> Promise<Void> {
        Promise { [weak self] (_, reject) in
            guard let self = self else { throw AppErr.nilSelf }

            guard let currentUser = self.dataService.currentUser else {
                debugPrint("[UserAccountService] user is not logged in")
                return reject(UserAccountServiceError.userIsNotLoggedIn)
            }
            let email = currentUser.email

            do {
                try self.storages.forEach { try $0.logOutUser(email: email) }
            } catch let error {
                reject(UserAccountServiceError.storage(error))
            }

            switch self.dataService.currentAuthType {
            case .oAuthGmail:
                try await(self.logOutGmailSession())
            case .password:
                try await(self.logOutImapUserSession())
            default:
                assertionFailure("User is not logged in")
                return reject(UserAccountServiceError.userIsNotLoggedIn)
            }
        }
    }

    private func logOutGmailSession() -> Promise<Void> {
        // TODO: - ANTON !!! GoogleUserService
        Promise(())
        // GoogleUserService.shared.signOut()
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

// MARK: - LogIn
extension UserAccountService {
    /// start session for a user, this method will log out current user if user was saved, save and start session for a new user
    func startFor(user type: SessionType) -> Promise<Void> {
        Promise<Void> { [weak self] (resolve, _) in
            guard let self = self else { throw AppErr.nilSelf }
            switch type {
            case let .google(email, name, token):
                // for google authentication this method will be called also on renewing access token
                // destroy storage in case a new user logged in
                if let currentUser = self.currentUser, currentUser.email != email {
                    try await(self.logOutCurrentUser())
                }
                // save new user data
                let user = UserObject.googleUser(
                    name: name,
                    email: email,
                    token: token
                )
                self.encryptedStorage.saveActiveUser(with: user)
                resolve(())
            case let .session(user):
                // perform log out only if user logged in
                if self.currentUser != nil {
                    try await(self.logOutCurrentUser())
                }
                self.encryptedStorage.saveActiveUser(with: user)
                // start session for saved user
                self.imap.setupSession()
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
}
