//
//  UserService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
// TODO: - ANTON - REMOVE
import GoogleSignIn
import Promises
import RealmSwift

import AppAuth
import GTMAppAuth

protocol UserServiceType {
    var accountService: UserAccountServiceType { get }

    func signOut() -> Promise<Void>
    func signIn(in viewController: UIViewController) -> Promise<Void>
    func renewSession() -> Promise<Void>
}

final class GoogleUserService: NSObject {
    private enum Constants {
        static let keychainIndex = "GTMAppAuthAuthorizerIndex"
    }

    var authorization: GTMAppAuthFetcherAuthorization? {
        GTMAppAuthFetcherAuthorization(fromKeychainForName: Constants.keychainIndex)
    }

    var token: String? {
        authorization?.authState.lastTokenResponse?.accessToken
    }

    let accountService: UserAccountServiceType

    init(accountService: UserAccountServiceType = UserAccountService()) {
        self.accountService = accountService
    }
}

extension GoogleUserService: UserServiceType {
    func renewSession() -> Promise<Void> {
        Promise<Void> { [weak self] resolve, reject in
            resolve(())
//            guard let self = self else { throw AppErr.nilSelf }
//            DispatchQueue.main.async {
//                self.onNewSession = { resolve(()) }
//                self.onError = { error in reject(error) }
//                self.googleManager.restorePreviousSignIn()
//            }
        }
    }

    private func fetchUser() {
        guard let authorization = authorization else {
            assertionFailure("authorization should not be nil at this point")
            return
        }

        guard let userInfoEndpoint = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo") else {
            assertionFailure("userInfoEndpoint should not be nil")
            return
        }

        let fetcherService = GTMSessionFetcherService()
        fetcherService.authorizer = authorization

        fetcherService.fetcher(with: userInfoEndpoint).beginFetch { [weak self] (data, error) in
            if let data = data {
                self?.handleUserInfo(data: data)
            } else if let error = error {
                self?.handleUserInfo(error: error)
            } else {
                assertionFailure("Inconsistent state for fetcher")
            }
        }
    }

    private func handleUserInfo(error: Error) {
        if (error as NSError).isEqual(OIDOAuthTokenErrorDomain) {
            debugPrint("Authorization error during token refresh, clearing state. \(error)")
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.keychainIndex)
        } else {
            debugPrint("Authorization error during fetching user info")
        }
    }

    private func handleUserInfo(data: Data) {
        print("^^ \(String(data: data, encoding: .utf8))")
    }

    func signIn(in viewController: UIViewController) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }

            let request = self.makeAuthorizationRequest()

            let googleAuthSession = OIDAuthState.authState(
                byPresenting: request,
                presenting: viewController
            ) { (authState, error) in
                if let authState = authState {
                    authState.stateChangeDelegate = self
                    self.saveAuth(state: authState)
                    self.fetchUser()
                    resolve(())
                } else if let error = error {
                    // TODO: - ANTON - handle errors
                    print("^^ error \(error)")
                    reject(error)
                } else {
                    assertionFailure()
                }
            }

            DispatchQueue.main.async {
                // save current session state to handle redirect url
                (UIApplication.shared.delegate as? AppDelegate)?.googleAuthSession = googleAuthSession
            }
        }
    }

    func signOut() -> Promise<Void> {
        Promise<Void> { resolve, reject in
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.keychainIndex)
        }
    }
}

// MARK: - Convenience
extension GoogleUserService {
    private func makeAuthorizationRequest() -> OIDAuthorizationRequest {
        OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: GeneralConstants.Gmail.clientID,
            scopes: GeneralConstants.Gmail.currentScope.map { $0.value },
            redirectURL: GeneralConstants.Gmail.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
    }

    // save auth session to keychain
    private func saveAuth(state: OIDAuthState) {
        let authorization: GTMAppAuthFetcherAuthorization = GTMAppAuthFetcherAuthorization(authState: state)
        GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: Constants.keychainIndex)
    }
}

// MARK: - OIDAuthStateChangeDelegate
extension GoogleUserService: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        saveAuth(state: state)
    }
}
// TODO: - ANTON
// dataService.startFor(user: .google(user.profile.email, name: user.profile.name, token: token))
