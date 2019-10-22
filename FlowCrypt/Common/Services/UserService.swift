//
//  UserService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn
import Promises
import RealmSwift

protocol UserServiceType {
    func setup()
    func signOut() -> Promise<Void>
    func signIn() -> Promise<Void>
    func renewAccessToken() -> Promise<String>
    func isSessionValid() -> Bool
}

final class UserService: NSObject, UserServiceType {
    static let shared = UserService()

    private var onLogin: ((User) -> Void)?
    private var onError: ((AppErr) -> Void)?
    private var onNewToken: ((String) -> Void)?
    private var onLogOut: (() -> Void)?

    private let googleManager: GIDSignIn
    private var dataManager: DataManager

    private init(
        googleManager: GIDSignIn = GIDSignIn.sharedInstance(),
        dataManager: DataManager = .shared
    ) {
        self.googleManager = googleManager
        self.dataManager = dataManager
        super.init()
    }

    func setup() {
        logDebug(100, "GoogleApi.setup()")
        GIDSignIn.sharedInstance().delegate = self
        if let token = dataManager.currentToken() {
            onNewToken?(token)
        }
    }

    func renewAccessToken() -> Promise<String> {
        return Promise<String> { [weak self] resolve, reject in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.googleManager.restorePreviousSignIn()
            }

            self.onNewToken = { token in
                resolve(token)
            }

            self.onError = { error in
                reject(error)
            }
        }
    }

    func signIn() -> Promise<Void> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.googleManager.signIn()
            }

            self.onLogin = { _ in
                resolve(())
            }

            self.onError = { error in
                reject(AppErr(error))
            }
        }
    }

    func signOut() -> Promise<Void> {
        return Promise<Void> { [weak self] resolve, reject in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.googleManager.signOut()
                self.googleManager.disconnect()
            }

            self.onLogOut = {
                resolve(())
            }

            self.onError = { error in
                reject(AppErr(error))
            }
        }
    }

    func isSessionValid() -> Bool {
        return dataManager.currentToken() != nil
            && dataManager.currentUser() != nil
    }
}

extension UserService: GIDSignInDelegate {
    func sign(_: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            let newUser = User(user)
            if dataManager.saveCurrent(user: newUser), let token = user.authentication.accessToken {
                dataManager.saveToken(with: token)
                onNewToken?(token)
                onLogin?(newUser)
            } else {
                onError?(AppErr.general("could not save user or retrieve token"))
            }
        } else {
            onError?(AppErr(error))
        }
    }

    func sign(_: GIDSignIn!, didDisconnectWith _: GIDGoogleUser!, withError _: Error!) {
        dataManager.logOut()

        do {
            Imap.instance.disconnect() // will not wait until disconnected. errors ignored
            let realm = try Realm()
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            onError?(AppErr.general("Could not properly finish signing out"))
        }

        onLogOut?()
    }
}
