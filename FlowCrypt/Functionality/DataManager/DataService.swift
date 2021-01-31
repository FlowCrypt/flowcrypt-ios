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
    var storage: Realm { get }

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
        case let .gmail(value): return value
        default: return nil
        }
    }

    private let encryptedStorage: EncryptedStorageType & LogOutHandler
    private(set) var localStorage: LocalStorageType & LogOutHandler

    private init(
        encryptedStorage: EncryptedStorageType & LogOutHandler = EncryptedStorage(),
        localStorage: LocalStorageType & LogOutHandler = LocalStorage()
    ) {
        self.encryptedStorage = encryptedStorage
        self.localStorage = localStorage
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
            try await(self.encryptedStorage.performMigrationIfNeeded())
            self.performTokenEncryptedMigration()
            self.performUserSessionMigration()
            self.performGmailApiMigration()
        }
    }

    /// Perform migration for users which has token saved in non encrypted storage
    private func performTokenEncryptedMigration() {
        let legacyTokenIndex = "keyCurrentToken"
        guard previouslyStoredUser() != nil else {
            debugPrint("Local migration not needed. User was not stored in local storage")
            return
        }
        guard let token = localStorage.storage.string(forKey: legacyTokenIndex) else {
            debugPrint("Local migration not needed. Token was not saved in local storage")
            return
        }

        performSessionMigration(with: token)
        localStorage.storage.removeObject(forKey: legacyTokenIndex)
    }

    /// Perform migration from google signing to generic session
    private func performUserSessionMigration() {
        guard let token = encryptedStorage.currentToken() else {
            debugPrint("User migration not needed. Token was not stored or migration already finished")
            return
        }

        performSessionMigration(with: token)
    }

    private func performSessionMigration(with token: String) {
        guard let user = previouslyStoredUser() else {
            debugPrint("User migration not needed. User was not stored or migration already finished")
            return
        }
        debugPrint("Perform user migration for token")
        let userObject = UserObject.googleUser(name: user.name, email: user.email, token: token)

        encryptedStorage.saveUser(with: userObject)
        UserDefaults.standard.set(nil, forKey: legacyCurrentUserIndex)
    }

    var legacyCurrentUserIndex: String { "keyCurrentUser" }
    private func previouslyStoredUser() -> User? {
        guard let data = UserDefaults.standard.object(forKey: legacyCurrentUserIndex) as? Data else { return nil }
        return try? PropertyListDecoder().decode(User.self, from: data)
    }

    /// Perform migration when Gmail Api implemented
    private func performGmailApiMigration() {
        let key = "KeyGmailApiMigration"
        let isMigrated = UserDefaults.standard.bool(forKey: key)
        guard !isMigrated else {
            return
        }
        UserDefaults.standard.set(true, forKey: key)
        let folders = storage.objects(FolderObject.self)

        do {
            try storage.write {
                storage.delete(folders)
            }
        } catch let error {
            assertionFailure("Can't perform Gmail Api migration \(error)")
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
