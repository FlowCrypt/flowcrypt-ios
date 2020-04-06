//
//  DataService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol DataServiceType {
    func startFor(user: User, with token: String?)
    
    var email: String? { get }
    var currentUser: User? { get }

    var isLoggedIn: Bool { get }
    var isSetupFinished: Bool { get }
    var currentAuthType: AuthType? { get }

    func keys() -> [PrvKeyInfo]?
    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)
    func publicKey() -> String?

    func logOutAndDestroyStorage()
}

final class DataService: DataServiceType {
    static let shared = DataService()

    var isSetupFinished: Bool {
        isLoggedIn && (self.encryptedStorage.keys()?.count ?? 0) > 0
    }

    var isLoggedIn: Bool {
        currentAuthType != nil
    }

    var email: String? {
        currentUser?.email
    }

    var currentUser: User? {
        localStorage.currentUser()
    }


    let encryptedStorage: EncryptedStorageType & LogOutHandler
    let localStorage: LocalStorageType & LogOutHandler
    let sessionProvider: SessionCredentialsProvider

    private init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage(),
        sessionProvider: SessionCredentialsProvider = ImapSessionService()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.sessionProvider = sessionProvider
    }
} 

extension DataService {
    var currentAuthType: AuthType? {
        // encrypted
        if let token = encryptedStorage.currentToken() {
            return .oAuth(token)
        }
        if let user = encryptedStorage.getUser(), let userPassword = user.password  {
            return .password(userPassword)
        }
        return nil
    }
}

// MARK: - Data
extension DataService {
    func keys() -> [PrvKeyInfo]? {
        guard let keys = encryptedStorage.keys() else { return nil }
        return Array(keys)
            .map(PrvKeyInfo.init)
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.addKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
    }

    func publicKey() -> String? {
        encryptedStorage.publicKey()
    }

    // TODO: ANTON - save user session credentials
    func startFor(user: User, with token: String?) {
//        if currentUser != user, currentUser != nil {
//            logOutAndDestroyStorage()
//        }
//        localStorage.saveCurrentUser(user: user)
//        encryptedStorage.saveToken(with: token)
    }
}

// MARK: - LogOut
extension DataService {
    func logOutAndDestroyStorage() {
        localStorage.logOut()
        encryptedStorage.logOut()
    }
}

// MARK: - DBMigration
extension DataService: DBMigration {
    func performMigrationIfNeeded() -> Promise<Void> {
        return Promise<Void> { [weak self] in
            guard let self = self else { throw AppErr.nilSelf }
            try await(self.encryptedStorage.performMigrationIfNeeded())
            self.performTokenEncryptedMigration()
            self.performUserSessionMigration()
        }
    }

    /// Perform migration for users which has token saved in non encrypted storage
    private func performTokenEncryptedMigration() {
        let legacyTokenIndex = "keyCurrentToken"
        guard localStorage.currentUser() != nil else {
            debugPrint("Local migration not needed. User was not stored")
            return
        }
        guard let token = localStorage.storage.string(forKey: legacyTokenIndex) else {
            debugPrint("Local migration not needed. Token was not saved")
            return
        }
        performSessionMigration(with: token)
        localStorage.storage.removeObject(forKey: legacyTokenIndex)
    }

    /// Perform migration from google signing to generic session
    private func performUserSessionMigration() {
        guard let token = encryptedStorage.currentToken() else {
            debugPrint("User migration not needed. Token was not stored")
            return
        }

        performSessionMigration(with: token)
    }

    private func performSessionMigration(with token: String) {
        guard let user = localStorage.currentUser() else {
            debugPrint("User migration not needed. User was not stored")
            return
        }

        let imapCreds = sessionProvider.getImapCredentials(for: user.email)
        let smtpCreds = sessionProvider.getImapCredentials(for: user.email)

        let userObject = UserObject(
            name: user.name,
            email: user.email,
            imap: SessionObject(
                hostname: imapCreds?.hostName ?? "imap.gmail.com",
                port: imapCreds?.port ?? 993,
                username: user.email,
                password: nil,
                oAuth2Token: token,
                connectionType: ConnectionType.tls.rawValue
            ),
            smtp: SessionObject(
                hostname: smtpCreds?.hostName ?? "smtp.gmail.com",
                port: smtpCreds?.port ?? 465,
                username: user.email,
                password: nil,
                oAuth2Token: token,
                connectionType: ConnectionType.tls.rawValue
            )
        )

        encryptedStorage.saveUser(with: userObject)
    }
}
