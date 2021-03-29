//
//  UserService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import RealmSwift
import AppAuth
import GTMAppAuth

protocol UserServiceType {
    var accountService: UserAccountServiceType { get }

    func signOut() -> Promise<Void>
    func signIn(in viewController: UIViewController) -> Promise<SessionType>
    func renewSession() -> Promise<Void>
}

enum GoogleUserServiceError: Error {
    case missedAuthorization
    case invalidUserEndpoint
    case serviceError(Error)
    case parsingError(Error)
    case inconsistentState(String)
}

struct GoogleUser: Codable {
    let name: String
    let picture: URL?
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

    func signIn(in viewController: UIViewController) -> Promise<SessionType> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }

            let request = self.makeAuthorizationRequest()

            let googleAuthSession = OIDAuthState.authState(
                byPresenting: request,
                presenting: viewController
            ) { (authState, error) in
                if let authState = authState {
                    self.saveAuth(state: authState)
                    
                    guard let email = GTMAppAuthFetcherAuthorization(authState: authState).userEmail else {
                        reject(GoogleUserServiceError.inconsistentState("Missed email"))
                        return
                    }

                    guard let token = authState.lastTokenResponse?.accessToken else {
                        reject(GoogleUserServiceError.inconsistentState("Missed token"))
                        return
                    }
                    
                    self.fetchGoogleUser { result in
                        switch result {
                        case .success(let user):
                            resolve(SessionType.google(email, name: user.name, token: token))
                        case .failure(let error):
                            self.handleUserInfo(error: error)
                            reject(error)
                        }
                    }
                } else if let error = error {
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
            scopes: GeneralConstants.Gmail.currentScope.map { $0.value } + [OIDScopeEmail],
            redirectURL: GeneralConstants.Gmail.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
    }

    // save auth session to keychain
    private func saveAuth(state: OIDAuthState) {
        state.stateChangeDelegate = self
        let authorization: GTMAppAuthFetcherAuthorization = GTMAppAuthFetcherAuthorization(authState: state)
        GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: Constants.keychainIndex)
    }

    private func fetchGoogleUser(_ completion: @escaping ((Result<GoogleUser, GoogleUserServiceError>) -> Void)) {
        guard let authorization = authorization else {
            assertionFailure("authorization should not be nil at this point")
            completion(.failure(.missedAuthorization))
            return
        }

        guard let userInfoEndpoint = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo") else {
            assertionFailure("userInfoEndpoint should not be nil")
            completion(.failure(.invalidUserEndpoint))
            return
        }

        let fetcherService = GTMSessionFetcherService()
        fetcherService.authorizer = authorization

        fetcherService.fetcher(with: userInfoEndpoint)
            .beginFetch { (data, error) in
                if let data = data {
                    do {
                        let user = try JSONDecoder().decode(GoogleUser.self, from: data)
                        completion(.success(user))
                    } catch let error {
                        completion(.failure(.parsingError(error)))
                    }
                } else if let error = error {
                    completion(.failure(.serviceError(error)))
                } else {
                    completion(.failure(.inconsistentState("Fetching user")))
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
}

// MARK: - OIDAuthStateChangeDelegate
extension GoogleUserService: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        // TODO: - ANTON - check if it's possible to save session here
        saveAuth(state: state)
    }
}
