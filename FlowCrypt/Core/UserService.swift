//
//  UserService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn
import RxSwift


final class UserService: NSObject {
    static let shared = UserService()

    var onLogin: Observable<User> { return _onLogin.asObservable() }
    private let _onLogin = PublishSubject<User>()

    var onLogOut: Observable<Void> { return _onLogOut.asObservable() }
    private let _onLogOut = PublishSubject<Void>()

    var onError: Observable<FCError> { return _onError.asObservable() }
    private let _onError = PublishSubject<FCError>()

    private let googleManager: GIDSignIn?
    private let dataManager: DataManager

    private init(
        googleManager: GIDSignIn? = GIDSignIn.sharedInstance(),
        dataManager: DataManager = .shared
    ) {
        self.googleManager = googleManager
        self.dataManager = dataManager
        super.init()
    }

    func setup() {
        Logger.debug(100, "GoogleApi.setup()")
        GIDSignIn.sharedInstance().delegate = self
        if let user = dataManager.currentUser() {
            _onLogin.onNext(user)
//            Logger.debug(101, "GoogleApi calling signInSilently")
//            // from docs: Attempts to sign in a previously authenticated user without interaction.  The delegate will be
//            // from docs: called at the end of this process indicating success or failure.
//            GIDSignIn.sharedInstance().signInSilently() // todo - we are not waiting for the delegate to be called here. This cauess imap calls to fail and transparently retry
//            // if we could force Imap calls to wait until this refresh is done, then imap calls would not have to needlessly retry
//            // "sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!)" - here is where it gets called back
//            Logger.debug(102, "GoogleApi calling signInSilently done")
        }
    }

    func renewAccessToken() {
        googleManager?.signInSilently()
    }

    func signIn() {
        googleManager?.signIn()
    }

    func signOut() {
        googleManager?.signOut()
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
            dataManager.saveToken(with: user.authentication.accessToken)
            if dataManager.saveCurrent(user: newUser) {
                _onLogin.onNext(newUser)
            } else {
                _onError.onNext(FCError.general)
            }
        } else {
            _onError.onNext(FCError(error))
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        _onLogOut.onNext(())
    }
}
