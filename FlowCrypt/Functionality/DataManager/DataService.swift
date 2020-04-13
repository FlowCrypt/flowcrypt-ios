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
    // data
    var email: String? { get }
    var currentUser: User? { get }
    var isLoggedIn: Bool { get }
    var isSetupFinished: Bool { get }
    var currentAuthType: AuthType? { get }

    // data
    var keys: [PrvKeyInfo]? { get }
    var publicKey: String? { get }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource)

    // login / logout
    func startFor(user type: SessionType)
    func logOutAndDestroyStorage()
}


protocol ImapSessionProvider {
    func imapSession() -> IMAPSession?
    func smtpSession() -> SMTPSession?
}


enum SessionType {
    case google(_ email: String, name: String, token: String)
    case session(_ userObject: UserObject)
}

final class DataService: DataServiceType {


    static let shared = DataService()

    var isSetupFinished: Bool {
        isLoggedIn && (self.encryptedStorage.keys()?.count ?? 0) > 0
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    var email: String? {
        currentUser?.email
    }

    var currentUser: User? {
        guard let userObject = self.encryptedStorage.getUser() else {
            return nil
        }
        return User(userObject)
    }

    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private let localStorage: LocalStorageType & LogOutHandler

    private init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
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
    var keys: [PrvKeyInfo]? {
        guard let keys = encryptedStorage.keys() else { return nil }
        return Array(keys)
            .map(PrvKeyInfo.init)
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.addKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
    }

    var publicKey: String? {
        encryptedStorage.publicKey()
    }

    /// Save user and user session credentials
    private func save(user userObject: UserObject) {
        if let currentUser = currentUser, currentUser.email != userObject.email {
            logOutAndDestroyStorage()
        }

        encryptedStorage.saveUser(with: userObject)
    }
}

// MARK: - LogOut
extension DataService {
    func logOutAndDestroyStorage() {
        localStorage.logOut()
        encryptedStorage.logOut()
    }
}

// MARK: - Migration
extension DataService: DBMigration {
    /// Perform all kind of migrations
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
            debugPrint("User migration not needed. User was not stored or migration already finished")
            return
        }

        let userObject = UserObject.googleUser(name: user.name, email: user.email, token: token)

        encryptedStorage.saveUser(with: userObject)
        localStorage.saveCurrentUser(user: nil)
    }
}

// MARK: - SessionProvider
extension DataService: ImapSessionProvider {
    func imapSession() -> IMAPSession? {

//        let net = SessionCredentialsService()
//        let email = "cryptup.tester@ukr.net"
//        let password = "HHjjdDVWqVZW96jP"
//        let imapCred = net.getImapCredentials(for: email)!
//        print("^^ imapCred \(imapCred)")
//
//        return IMAPSession(
//            hostname: imapCred.hostName!,
//            port: imapCred.port,
//            email: email,
//            authType: .password(password),
//            connectionType: .tls
//        )


        //        return IMAPSession(
        //            hostname: imap.hostName!,
        //            port: imap.port,
        //            username: "antonflowcrypt@yahoo.com",
        //            password: "flowcryptpassword123",
        //            oAuth2Token: "NO ACCESS TOKEN",
        //            authType: .xoAuth2,
        //            connectionType: imap.connectionType
        //        )

        guard let user = encryptedStorage.getUser() else {
            assertionFailure("Can't get IMAP Session without user data")
            return nil
        }

        guard let imap = user.imap else {
            assertionFailure("Can't get IMAP Session without user data")
            return nil
        }

        guard let auth = user.authType, let connection = ConnectionType(rawValue: imap.connectionType) else {
            assertionFailure("Authentication type should be defined on this step")
            return nil
        }

        return IMAPSession(
            hostname: imap.hostname,
            port: imap.port,
            email: user.email,
            authType: auth,
            connectionType: connection
        )
    }

    func smtpSession() -> SMTPSession? {
//        let net = SessionCredentialsService()
//        let email = "cryptup.tester@ukr.net"
//        let password = "HHjjdDVWqVZW96jP"
//        let smtpCred = net.getSmtpCredentials(for: email)!
//        print("^^ smtpCred \(smtpCred)")
//
//        return SMTPSession(
//            hostname: smtpCred.hostName!,
//            port: smtpCred.port,
//            email: email,
//            authType: .password(password),
//            connectionType: .tls
//        )


        guard let user = encryptedStorage.getUser() else {
            assertionFailure("Can't get SMTP Session without user data")
            return nil
        }

        guard let smtp = user.smtp else {
            assertionFailure("Can't get SMTP Session without user data")
            return nil
        }

        guard let auth = user.authType, let connection = ConnectionType(rawValue: smtp.connectionType) else {
            assertionFailure("Authentication type should be defined on this step")
            return nil
        }

        return SMTPSession(
            hostname: smtp.hostname,
            port: smtp.port,
            email: user.email,
            authType: auth,
            connectionType: connection
        )
    }
}

extension DataService {
    func startFor(user type: SessionType) {
        switch type {
        case let .google(email, name, token):
            let user = UserObject.googleUser(
                name: name,
                email: email,
                token: token
            )
            save(user: user)
        case let .session(userObject):
            // TODO: ANTON - Create user object here
            save(user: userObject)
            break
        }
    }
}
