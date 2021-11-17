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
    func signIn(in viewController: UIViewController, scopes: [String]) async throws -> SessionType
    func renewSession() async throws
}

enum GoogleUserServiceError: Error {
    case missedAuthorization
    case invalidUserEndpoint
    case inconsistentState(String)
    case userNotAllowedAllNeededScopes(missingScopes: [GoogleScope])
}

struct GoogleUser: Codable {
    let name: String
    let picture: URL?
}

protocol GoogleUserServiceType {
    var authorization: GTMAppAuthFetcherAuthorization? { get }
    func renewSession() async throws
}

final class GoogleUserService: NSObject, GoogleUserServiceType {

    private enum Constants {
        static let index = "GTMAppAuthAuthorizerIndex"
        static let userInfoUrl = "https://www.googleapis.com/oauth2/v3/userinfo"
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

    @MainActor func signIn(in viewController: UIViewController, scopes: [String]) async throws -> SessionType {
        return try await withCheckedThrowingContinuation { continuation in
            let request = self.makeAuthorizationRequest(scopes: scopes)
            let googleAuthSession = OIDAuthState.authState(
                byPresenting: request,
                presenting: viewController
            ) { authState, authError in
                guard let authState = authState else {
                    let error = authError ?? AppErr.unexpected("Shouldn't happen because covered received non nil error and non nil authState")
                    return continuation.resume(throwing: error)
                }

                Task<Void, Never> {
                    do {
                        return continuation.resume(returning: try await self.handleGoogleAuthStateResult(authState))
                    } catch {
                        return continuation.resume(throwing: error)
                    }
                }
            }
            self.appDelegate?.googleAuthSession = googleAuthSession
        }
    }

    func signOut(user email: String) {
        DispatchQueue.main.async {
            self.appDelegate?.googleAuthSession = nil
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.index + email)
        }
    }

    private func handleGoogleAuthStateResult(_ authState: OIDAuthState) async throws -> SessionType {
        let missingScopes = self.checkMissingScopes(authState.scope)
        if missingScopes.isNotEmpty {
            throw GoogleUserServiceError.userNotAllowedAllNeededScopes(missingScopes: missingScopes)
        }
        let authorization = GTMAppAuthFetcherAuthorization(authState: authState)
        guard let email = authorization.userEmail else {
            throw GoogleUserServiceError.inconsistentState("Missed email")
        }
        self.saveAuth(state: authState, for: email)
        guard let token = authState.lastTokenResponse?.accessToken else {
            throw GoogleUserServiceError.inconsistentState("Missed token")
        }
        let user = try await self.fetchGoogleUser(with: authorization)
        return SessionType.google(email, name: user.name, token: token)
    }
}

// MARK: - Convenience
extension GoogleUserService {

    private func makeAuthorizationRequest(scopes: [String]) -> OIDAuthorizationRequest {
        OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: GeneralConstants.Gmail.clientID,
            scopes: scopes,
            redirectURL: GeneralConstants.Gmail.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
    }

    // save auth session to keychain
    private func saveAuth(state: OIDAuthState, for email: String) {
        state.stateChangeDelegate = self
        let authorization = GTMAppAuthFetcherAuthorization(authState: state)
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

    // todo - isn't this call supported by Google client library?
    private func fetchGoogleUser(
        with authorization: GTMAppAuthFetcherAuthorization
    ) async throws -> GoogleUser {
        guard let url = URL(string: Constants.userInfoUrl) else {
            throw AppErr.unexpected("URL(Constants.userInfoUrl) nil")
        }
        let fetcherService = GTMSessionFetcherService()
        fetcherService.authorizer = authorization
        do {
            let data = try await fetcherService.fetcher(with: url).beginFetch()
            return try JSONDecoder().decode(GoogleUser.self, from: data)
        } catch {
            let isTokenErr = (error as NSError).isEqual(OIDOAuthTokenErrorDomain)
            if isTokenErr, let email = self.currentUserEmail {
                self.logger.logError("Authorization error during token refresh, clearing state. \(error)")
                // removes any authorisation information which was stored in Keychain, the same happens on logout.
                // if any error happens during token refresh then user will be signed out automatically.
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.index + email)
            }
            throw error
        }
    }

    private func checkMissingScopes(_ scope: String?) -> [GoogleScope] {
        let authScope = GeneralConstants.Gmail.basicScope
        guard let scope = scope else { return authScope }
        return authScope.filter { !scope.contains($0.value) }
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
