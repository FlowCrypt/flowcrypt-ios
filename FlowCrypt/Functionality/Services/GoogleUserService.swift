//
//  UserService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AppAuth
import FlowCryptCommon
import Foundation
import GTMAppAuth
import RealmSwift

protocol UserServiceType {
    func signOut(user email: String)
    func signIn(in viewController: UIViewController) async throws -> SessionType
    func renewSession() async throws
}

enum GoogleUserServiceError: Error {
    case missedAuthorization
    case invalidUserEndpoint
    case serviceError(Error)
    case parsingError(Error)
    case inconsistentState(String)
    case userNotAllowedAllNeededScopes(missingScopes: [GoogleScope])
}

struct GoogleUser: Codable {
    let name: String
    let picture: URL?
}

protocol GoogleUserServiceType {
    var authorization: GTMAppAuthFetcherAuthorization? { get }
    func renewSession() async throws -> Void
}

final class GoogleUserService: NSObject, GoogleUserServiceType {

    private enum Constants {
        static let index = "GTMAppAuthAuthorizerIndex"
    }
    private lazy var logger = Logger.nested(in: Self.self, with: .userAppStart)

    var userToken: String? {
        authorization?.authState
            .lastTokenResponse?
            .accessToken
    }

    var idToken: String? {
        authorization?.authState
            .lastTokenResponse?
            .idToken
    }

    var authorization: GTMAppAuthFetcherAuthorization? {
        getAuthorizationForCurrentUser()
    }

    private var currentUserEmail: String? {
        DataService.shared.email
    }
}

extension GoogleUserService: UserServiceType {
    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    func renewSession() async throws {
        // GTMAppAuth should renew session via OIDAuthStateChangeDelegate
    }

    func signIn(in viewController: UIViewController) async throws -> SessionType {
        return try await withCheckedThrowingContinuation { continuation in
            let request = self.makeAuthorizationRequest()
            let googleAuthSession = OIDAuthState.authState(
                byPresenting: request,
                presenting: viewController
            ) { authState, error in
                if let authState = authState {
                    let missingScopes = self.checkMissingScopes(authState.scope)
                    if !missingScopes.isEmpty {
                        return continuation.resume(throwing: GoogleUserServiceError.userNotAllowedAllNeededScopes(missingScopes: missingScopes))
                    }
                    let authorization = GTMAppAuthFetcherAuthorization(authState: authState)
                    guard let email = authorization.userEmail else {
                        return continuation.resume(throwing: GoogleUserServiceError.inconsistentState("Missed email"))
                    }
                    self.saveAuth(state: authState, for: email)
                    guard let token = authState.lastTokenResponse?.accessToken else {
                        return continuation.resume(throwing: GoogleUserServiceError.inconsistentState("Missed token"))
                    }
                    self.fetchGoogleUser(with: authorization) { result in
                        switch result {
                        case .success(let user):
                            return continuation.resume(returning: SessionType.google(email, name: user.name, token: token))
                        case .failure(let error):
                            self.handleUserInfo(error: error)
                            return continuation.resume(throwing: error)
                        }
                    }
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("Shouldn't happe because covered received non nil error and non nil authState")
                }
            }
            DispatchQueue.main.sync { // because of MainActor. Wrong?
                appDelegate?.googleAuthSession = googleAuthSession
            }
        }
    }

    func signOut(user email: String) {
        DispatchQueue.main.sync { // because of MainActor. Wrong?
            appDelegate?.googleAuthSession = nil
        }
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.index + email)
    }
}

// MARK: - Convenience
extension GoogleUserService {

    private func makeAuthorizationRequest() -> OIDAuthorizationRequest {
        OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: GeneralConstants.Gmail.clientID,
            scopes: GeneralConstants.Gmail.currentScope.map(\.value) + [OIDScopeEmail],
            redirectURL: GeneralConstants.Gmail.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
    }

    // save auth session to keychain
    private func saveAuth(state: OIDAuthState, for email: String) {
        state.stateChangeDelegate = self
        let authorization: GTMAppAuthFetcherAuthorization = GTMAppAuthFetcherAuthorization(authState: state)
        GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: Constants.index + email)
    }

    private func getAuthorizationForCurrentUser() -> GTMAppAuthFetcherAuthorization? {
        // get active user
        guard let email = currentUserEmail else {
            return nil
        }
        // get authorization from keychain
        return GTMAppAuthFetcherAuthorization(fromKeychainForName: Constants.index + email)
    }

    private func fetchGoogleUser(
        with authorization: GTMAppAuthFetcherAuthorization?,
        completion: @escaping ((Result<GoogleUser, GoogleUserServiceError>) -> Void)
    ) {
        guard let authorization = authorization else {
            fatalError("authorization should not be nil at this point")
        }

        guard let userInfoEndpoint = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo") else {
            fatalError("userInfoEndpoint could not be nil because it's hardcoded string url")
        }

        let fetcherService = GTMSessionFetcherService()
        fetcherService.authorizer = authorization

        fetcherService.fetcher(with: userInfoEndpoint)
            .beginFetch { data, error in
                if let data = data {
                    do {
                        let user = try JSONDecoder().decode(GoogleUser.self, from: data)
                        completion(.success(user))
                    } catch {
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
            logger.logError("Authorization error during token refresh, clearing state. \(error)")
            if let email = currentUserEmail {
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.index + email)
            }
        } else {
            logger.logError("Authorization error during fetching user info")
        }
    }

    private func checkMissingScopes(_ scope: String?) -> [GoogleScope] {
        guard let scope = scope else {
            return GoogleScope.allCases
        }
        return GoogleScope.allCases.filter { !scope.contains($0.value) }
    }
}

// MARK: - OIDAuthStateChangeDelegate
extension GoogleUserService: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        guard let email = currentUserEmail else {
            return
        }

        saveAuth(state: state, for: email)
    }
}
