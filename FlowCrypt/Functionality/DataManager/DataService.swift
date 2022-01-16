//
//  DataService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

// todo DataServiceType in general is a bit of a confused class
// hopefully we can refactor it away or shrink it
protocol DataServiceType {
    // data
    var email: String? { get }
    var currentUser: User? { get }
    var isLoggedIn: Bool { get }
    var isSetupFinished: Bool { get }
    var currentAuthType: AuthType? { get }
    var token: String? { get }

    var users: [User] { get }

    func getFinishedSetupUsers(exceptUserEmail: String) -> [User]

    func performMigrationIfNeeded() async throws
}

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
}

// MARK: - DataService
final class DataService {

    private let encryptedStorage: EncryptedStorageType
    private let localStorage: LocalStorageType
    private let migrationService: DBMigration

    init(
        encryptedStorage: EncryptedStorageType,
        localStorage: LocalStorageType = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.migrationService = DBMigrationService(localStorage: localStorage, encryptedStorage: encryptedStorage)
    }
}

// MARK: - DataServiceType
extension DataService: DataServiceType {
    var isSetupFinished: Bool {
        isLoggedIn && doesAnyKeyExistForCurrentUser
    }

    private var doesAnyKeyExistForCurrentUser: Bool {
        guard let currentUser = currentUser else {
            return false
        }
        return encryptedStorage.doesAnyKeypairExist(for: currentUser.email)
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    var email: String? {
        currentUser?.email
    }

    // helper to get current user object from DB
    private var activeUser: User? {
        encryptedStorage.activeUser
    }

    var users: [User] {
        encryptedStorage.getAllUsers()
    }

    var currentUser: User? {
        encryptedStorage.getAllUsers().first(where: \.isActive)
    }

    var currentAuthType: AuthType? {
        activeUser?.authType
    }

    var token: String? {
        switch currentAuthType {
        case .oAuthGmail:
            return GoogleUserService(
                currentUserEmail: currentUser?.email,
                appDelegateGoogleSessionContainer: nil // needed only when signing in/out
            ).accessToken
        default:
            guard let currentUser = currentUser else {
                return nil
            }
            return Imap(user: currentUser).imapSess?.oAuth2Token
        }
    }

    func getFinishedSetupUsers(exceptUserEmail: String) -> [User] {
        encryptedStorage.getAllUsers()
            .filter { $0.email != exceptUserEmail }
            .filter { encryptedStorage.doesAnyKeypairExist(for: $0.email) }
    }
}

// MARK: - Migration
extension DataService: DBMigration {
    /// Perform all kind of migrations
    func performMigrationIfNeeded() async throws {
        try await migrationService.performMigrationIfNeeded()
    }
}
