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
    func signIn(in viewController: UIViewController, scopes: [GoogleScope]) async throws -> SessionType
    func renewSession() async throws
}

enum GoogleUserServiceError: Error, CustomStringConvertible {
    case cancelledAuthorization
    case contextError(String)
    case inconsistentState(String)
    case userNotAllowedAllNeededScopes(missingScopes: [GoogleScope])

    var description: String {
        switch self {
        case .cancelledAuthorization:
            return "Authorization was cancelled"
        case .contextError(let message):
            return "Context error: \(message)"
        case .inconsistentState(let message):
            return "Inconsistent state error: \(message)"
        case .userNotAllowedAllNeededScopes(let missingScopes):
            return "Missing scopes error: \(missingScopes.map(\.title).joined(separator: ", "))"
        }
    }
}

struct GoogleUser: Codable {
    let name: String
    let picture: URL?
}

protocol GoogleUserServiceType {
    var authorization: GTMAppAuthFetcherAuthorization? { get }
    func renewSession() async throws
}

// this is here so that we don't have to include AppDelegate in test target
protocol AppDelegateGoogleSesssionContainer {
    var googleAuthSession: OIDExternalUserAgentSession? { get set }
}

// todo - should be refactored to not require currentUserEmail
final class GoogleUserService: NSObject, GoogleUserServiceType {

    let currentUserEmail: String?
    var appDelegateGoogleSessionContainer: AppDelegateGoogleSesssionContainer?

    init(
        currentUserEmail: String?,
        appDelegateGoogleSessionContainer: AppDelegateGoogleSesssionContainer? = nil
    ) {
        self.appDelegateGoogleSessionContainer = appDelegateGoogleSessionContainer
        self.currentUserEmail = currentUserEmail
    }

    private enum Constants {
        static let index = "GTMAppAuthAuthorizerIndex"
        static let userInfoUrl = "https://www.googleapis.com/oauth2/v3/userinfo"
    }

    private lazy var logger = Logger.nested(in: Self.self, with: .userAppStart)

    private var tokenResponse: OIDTokenResponse? {
        authorization?.authState.lastTokenResponse
    }

    var userToken: String? {
        tokenResponse?.accessToken
    }

    var idToken: String? {
        tokenResponse?.idToken
    }

    var authorization: GTMAppAuthFetcherAuthorization? {
        getAuthorizationForCurrentUser()
    }

}

extension GoogleUserService: UserServiceType {

    func renewSession() async throws {
        // GTMAppAuth should renew session via OIDAuthStateChangeDelegate
    }

    @MainActor func signIn(in viewController: UIViewController, scopes: [GoogleScope]) async throws -> SessionType {
        return try await withCheckedThrowingContinuation { continuation in
            let request = self.makeAuthorizationRequest(scopes: scopes)
            let googleDelegateSess = OIDAuthState.authState(
                byPresenting: request,
                presenting: viewController
            ) { [weak self] authState, authError in
                guard let self = self else { return }
                guard let authState = authState else {
                    if let authError = authError {
                        let error = self.parseSignInError(authError)
                        return continuation.resume(throwing: error)
                    } else {
                        let error = AppErr.unexpected("Shouldn't happen because received nil error and nil authState")
                        return continuation.resume(throwing: error)
                    }
                }
                Task<Void, Never> {
                    do {
                        return continuation.resume(returning: try await self.handleGoogleAuthStateResult(authState, scopes: scopes))
                    } catch {
                        return continuation.resume(throwing: error)
                    }
                }
            }
            self.appDelegateGoogleSessionContainer?.googleAuthSession = googleDelegateSess
        }
    }

    func performTokenRefresh() async throws -> (accessToken: String, idToken: String) {
        return try await withCheckedThrowingContinuation { continuation in
            authorization?.authState.setNeedsTokenRefresh()
            authorization?.authState.performAction { accessToken, idToken, error in
                guard let accessToken = accessToken, let idToken = idToken else {
                    let tokenError = error ?? AppErr.unexpected("Shouldn't happen because received nil error and nil token")
                    return continuation.resume(throwing: tokenError)
                }
                let result = (accessToken, idToken)
                return continuation.resume(with: .success(result))
            }
        }
    }

    func signOut(user email: String) {
        DispatchQueue.main.async {
            self.appDelegateGoogleSessionContainer?.googleAuthSession = nil
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.index + email)
        }
    }

    private func parseSignInError(_ error: Error) -> Error {
        guard let underlyingError = (error as NSError).userInfo["NSUnderlyingError"] as? NSError
        else { return error }

        switch underlyingError.code {
        case 1:
            return GoogleUserServiceError.cancelledAuthorization
        case 2:
            return GoogleUserServiceError.contextError("A context wasn’t provided.")
        case 3:
            return GoogleUserServiceError.contextError("The context was invalid.")
        default:
            return error
        }
    }

    private func handleGoogleAuthStateResult(_ authState: OIDAuthState, scopes: [GoogleScope]) async throws -> SessionType {
        let missingScopes = self.checkMissingScopes(authState.scope, from: scopes)
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

    private func makeAuthorizationRequest(scopes: [GoogleScope]) -> OIDAuthorizationRequest {
        OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: GeneralConstants.Gmail.clientID,
            scopes: scopes.map(\.value),
            redirectURL: GeneralConstants.Gmail.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: ["include_granted_scopes": "true"]
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
            if isTokenErr, let email = currentUserEmail {
                self.logger.logError("Authorization error during token refresh, clearing state. \(error)")
                // removes any authorisation information which was stored in Keychain, the same happens on logout.
                // if any error happens during token refresh then user will be signed out automatically.
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Constants.index + email)
            }
            throw error
        }
    }

    private func checkMissingScopes(_ scope: String?, from scopes: [GoogleScope]) -> [GoogleScope] {
        guard let allowedScopes = scope?.split(separator: " ").map(String.init),
              allowedScopes.isNotEmpty
        else { return scopes }
        return scopes.filter { !allowedScopes.contains($0.value) }
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
