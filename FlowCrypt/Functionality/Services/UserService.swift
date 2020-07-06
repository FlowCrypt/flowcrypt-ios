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
    func renewSession() -> Promise<Void>
}

final class UserService: NSObject  {
    static let shared = UserService()

    private var onLogin: (() -> Void)?
    private var onError: ((AppErr) -> Void)?
    private var onNewSession: (() -> Void)?
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
        guard let authType = dataService.currentAuthType else {
            assertionFailure("User should be authenticated on this step")
            return
        }
        switch authType {
        case .oAuth:
            if dataService.isLoggedIn {
                onLogin?()
            }
        case let .password(password):
            assertionFailure("Implement this one")
        }
    }

}

extension UserService: UserServiceType {

    func renewSession() -> Promise<Void> {
        Promise<Void> { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }
            DispatchQueue.main.async {
                self.onNewSession = { resolve(()) }
                self.onError = { error in reject(error) }
                self.googleManager.restorePreviousSignIn()
            }
        }
    }

    func signIn() -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.onLogin = { resolve(()) }
                self.onError = { error in reject(AppErr(error)) }
                self.googleManager.signIn()
            }
        }
    }

    func signOut() -> Promise<Void> {
        Promise<Void> { [weak self] resolve, reject in
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

        dataService.startFor(user: .google(user.profile.email, name: user.profile.name, token: token))
        onNewSession?()
        onLogin?()
    }

    func sign(_: GIDSignIn!, didDisconnectWith _: GIDGoogleUser!, withError _: Error!) {
        // will not wait until disconnected. errors ignored
        Imap.shared.disconnect()
        dataService.logOutAndDestroyStorage()
        onLogOut?()
    }
}
