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

final class UserAccountService: UserAccountServiceType {
    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private let localStorage: LocalStorageType & LogOutHandler
    private let dataService: DataServiceType

    init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage(),
        dataService: DataServiceType = DataService.shared
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.dataService = dataService
    }

    private var currentUser: User? {
        dataService.currentUser
    }

    private var storages: [LogOutHandler] {
        [encryptedStorage, localStorage]
    }

    func logOutCurrentUser() -> Promise<Void> {
        guard let currentUser = dataService.currentUser else {
            debugPrint("[UserAccountService] user is not logged in")
            return Promise(())
        }
        let email = currentUser.email
        storages.forEach { $0.logOutUser(email: email) }

        switch dataService.currentAuthType {
        case .oAuthGmail:
            return logOutGmailSession()
        case .password:
            return logOutImapUserSession()
        default:
            // TODO: - ANTON - consider reject with error
            assertionFailure("User is not logged in")
            return Promise(())
        }
    }

    private func logOutGmailSession() -> Promise<Void> {
        GoogleUserService.shared.signOut()
    }

    private func logOutImapUserSession() -> Promise<Void> {
        Promise<Void> { (resolve, _) in
            // TODO: - ANTON - inject
            Imap.shared.disconnect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                resolve(())
            }
        }
    }

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
                try await(self.logOutCurrentUser())
                self.encryptedStorage.saveActiveUser(with: user)
                // start session for saved user
                Imap.shared.setupSession()
            }
        }
    }
}
