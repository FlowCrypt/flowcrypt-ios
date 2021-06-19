//
//  DataService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import RealmSwift

protocol DataServiceType: EmailProviderType {
    // data
    var email: String? { get }
    var currentUser: User? { get }
    var isLoggedIn: Bool { get }
    var isSetupFinished: Bool { get }
    var currentAuthType: AuthType? { get }
    var token: String? { get }

    var users: [User] { get }

    func validAccounts() -> [User]
}

protocol ImapSessionProvider {
    func imapSession() -> IMAPSession?
    func smtpSession() -> SMTPSession?
}

enum SessionType: CustomStringConvertible {
    case google(_ email: String, name: String, token: String)
    case session(_ userObject: UserObject)

    var description: String {
        switch self {
        case let .google(email, name, _):
            return "Google \(email) \(name)"
        case let .session(user):
            return "Session \(user.email)"
        }
    }
}

// MARK: - DataService
final class DataService {
    static let shared = DataService()

    private let encryptedStorage: EncryptedStorageType
    private let localStorage: LocalStorageType
    private let migrationService: DBMigration

    private init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage(),
        localStorage: LocalStorageType = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.migrationService = DBMigrationService(localStorage: localStorage, encryptedStorage: encryptedStorage)
    }
}

// MARK: - DataServiceType
extension DataService: DataServiceType {
    var storage: Realm {
        encryptedStorage.storage
    }

    var isSetupFinished: Bool {
        isLoggedIn && isAnyKeysForCurrentUser
    }

    private var isAnyKeysForCurrentUser: Bool {
        guard let currentUser = currentUser else {
            return false
        }
        return encryptedStorage.isAnyKey(for: currentUser.email)
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    var email: String? {
        currentUser?.email
    }

    // helper to get current user object from DB
    private var currentUserObject: UserObject? {
        encryptedStorage.getAllUsers().first(where: \.isActive)
    }

    var users: [User] {
        encryptedStorage.getAllUsers()
            .map(User.init)
    }

    var currentUser: User? {
        users.first(where: \.isActive)
    }

    var currentAuthType: AuthType? {
        currentUserObject?.authType
    }

    var token: String? {
        switch currentAuthType {
        case .oAuthGmail:
            return GoogleUserService().userToken
        default:
            return nil
        }
    }

    func validAccounts() -> [User] {
        encryptedStorage.getAllUsers()
            .filter { encryptedStorage.isAnyKey(for: $0.email) }
            .filter { $0.email != currentUser?.email }
            .map(User.init)
    }
}

// MARK: - Migration
extension DataService: DBMigration {
    /// Perform all kind of migrations
    func performMigrationIfNeeded() -> Promise<Void> {
        migrationService.performMigrationIfNeeded()
    }
}

// MARK: - SessionProvider
extension DataService: ImapSessionProvider {
    func imapSession() -> IMAPSession? {
        guard let user = currentUserObject else {
            assertionFailure("Can't get IMAP Session without user data")
            return nil
        }

        guard let imapSession = IMAPSession(userObject: user) else {
            assertionFailure("couldn't create IMAP Session with this parameters")
            return nil
        }

        return imapSession
    }

    func smtpSession() -> SMTPSession? {
        guard let user = currentUserObject else {
            assertionFailure("Can't get SMTP Session without user data")
            return nil
        }

        guard let smtpSession = SMTPSession(userObject: user) else {
            assertionFailure("couldn't create SMTP Session with this parameters")
            return nil
        }

        return smtpSession
    }
}
