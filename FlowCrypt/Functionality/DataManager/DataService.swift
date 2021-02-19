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

protocol DataServiceType {
//    var storage: Realm { get }

    // data
    var email: String? { get }
    var currentUser: User? { get }
    var isLoggedIn: Bool { get }
    var isSetupFinished: Bool { get }
    var currentAuthType: AuthType? { get }
    var token: String? { get }

    // Local data
    var trashFolderPath: String? { get }
    func saveTrashFolder(path: String?)

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

// MARK: - DataService
final class DataService: DataServiceType {
    static let shared = DataService()

    var storage: Realm {
        encryptedStorage.storage
    }

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

    var currentAuthType: AuthType? {
        encryptedStorage.getUser()?.authType
    }

    var token: String? {
        switch currentAuthType {
        case let .oAuthGmail(value): return value
        default: return nil
        }
    }

    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private(set) var localStorage: LocalStorageType & LogOutHandler
    private let migrationService: DBMigration

    private init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
        self.migrationService = DBMigrationService(localStorage: localStorage, encryptedStorage: encryptedStorage)
    }
}

// MARK: - DataKeyServiceType
extension DataService: KeyDataServiceType {
    var keys: [PrvKeyInfo]? {
        guard let keys = encryptedStorage.keys() else { return nil }
        return Array(keys).map(PrvKeyInfo.init)
    }

    var publicKey: String? {
        encryptedStorage.publicKey()
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.addKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
    }

    func updateKeys(keyDetails: [KeyDetails], passPhrase: String, source: KeySource) {
        encryptedStorage.updateKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source)
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
            // migrate to encrypted storage
            try await(self.encryptedStorage.performMigrationIfNeeded())
            // migrate all other type of migrations
            try await(self.migrationService.performMigrationIfNeeded())
        }
    }
}

// MARK: - SessionProvider
extension DataService: ImapSessionProvider {
    func imapSession() -> IMAPSession? {
        guard let user = encryptedStorage.getUser() else {
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
        guard let user = encryptedStorage.getUser() else {
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

// MARK: -
extension DataService {
    func startFor(user type: SessionType) {
        switch type {
        case let .google(email, name, token):
            // for google authentication this method will be called also on renewing access token
            // destroy storage in case a new user logged in
            if let currentUser = currentUser, currentUser.email != email {
                logOutAndDestroyStorage()
            }
            // save new user data
            let user = UserObject.googleUser(
                name: name,
                email: email,
                token: token
            )
            encryptedStorage.saveUser(with: user)
        case let .session(user):
            logOutAndDestroyStorage()
            encryptedStorage.saveUser(with: user)
        }
    }
}

extension DataService {
    var trashFolderPath: String? {
        localStorage.trashFolderPath
    }

    func saveTrashFolder(path: String?) {
        localStorage.trashFolderPath = path
    }
}
