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
    private var onError: ((FCError) -> Void)?
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
                self.googleManager.signInSilently()
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

            self.onLogin = { token in
                resolve(())
            }

            self.onError = { error in
                reject(FCError(error))
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
                reject(FCError(error))
            }
        }
    }

    func isSessionValid() -> Bool {
        return dataManager.currentToken() != nil
            && dataManager.currentUser() != nil
    }
}

extension UserService: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            let newUser = User(user)
            if dataManager.saveCurrent(user: newUser), let token = user.authentication.accessToken {
                dataManager.saveToken(with: token)
                onNewToken?(token)
                onLogin?(newUser)
            } else {
                onError?(FCError.general)
            }
        } else {
            onError?(FCError(error))
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        dataManager.logOut()

        do {
            let realm = try Realm()
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            onError?(FCError.general)
        }

        onLogOut?()
    }
}
