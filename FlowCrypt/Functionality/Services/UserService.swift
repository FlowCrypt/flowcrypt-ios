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
    func signOut() -> Promise<Void>
    func signIn() -> Promise<Void>
    func renewSession() -> Promise<String>
}

final class UserService: NSObject  {
    static let shared = UserService()

    private var onLogin: ((User) -> Void)?
    private var onError: ((AppErr) -> Void)?
    private var onNewToken: ((String) -> Void)?
    private var onLogOut: (() -> Void)?

    private let googleManager: GIDSignIn
    private var dataService: DataServiceType

    private init(
        googleManager: GIDSignIn = GIDSignIn.sharedInstance(),
        dataService: DataServiceType = DataService.shared
    ) {
        self.googleManager = googleManager
        self.dataService = dataService
        super.init()
    }

    func setup() {
        if let token = dataService.currentToken {
            onNewToken?(token)
        }
        if let user = dataService.currentUser {
            onLogin?(user)
        }
    }
}

extension UserService: UserServiceType {

    func renewSession() -> Promise<String> {
        return Promise<String> { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }
            DispatchQueue.main.async {
                self.onNewToken = { token in resolve(token) }
                self.onError = { error in reject(error) }
                self.googleManager.restorePreviousSignIn()
            }
        }
    }

    func signIn() -> Promise<Void> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.onLogin = { _ in resolve(()) }
                self.onError = { error in reject(AppErr(error)) }
                self.googleManager.signIn()
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
            self.onLogOut = { resolve(()) }
            self.onError = { error in reject(AppErr(error)) }
        }
    }
}

extension UserService: GIDSignInDelegate {
    func sign(_: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            onError?(AppErr(error))
            return
        }
        guard let token = user.authentication.accessToken else {
            onError?(AppErr.general("could not save user or retrieve token"))
            return
        }
        let user = User(user)
        dataService.startFor(user: user, with: token)
        onNewToken?(token)
        onLogin?(user)
    }

    func sign(_: GIDSignIn!, didDisconnectWith _: GIDGoogleUser!, withError _: Error!) {
        // will not wait until disconnected. errors ignored
        Imap.shared.disconnect()
        dataService.logOutAndDestroyStorage()
        onLogOut?()
    }
}
