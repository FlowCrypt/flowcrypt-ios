//
//  GoogleAuthManager.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AppAuth
import FlowCryptCommon
import GoogleAPIClientForREST_Oauth2
import GTMAppAuth
import RealmSwift

enum GoogleAuthManagerError: Error, CustomStringConvertible {
    case cancelledAuthorization
    case wrongAccount(String, String)
    case contextError(String)
    case inconsistentState(String)
    case userNotAllowedAllNeededScopes(missingScopes: [GoogleScope], email: String?)

    var description: String {
        switch self {
        case .cancelledAuthorization:
            return "google_user_service_error_auth_cancelled".localized
        case let .wrongAccount(signedAccount, currentAccount):
            return "google_user_service_error_wrong_account".localizeWithArguments(
                signedAccount, currentAccount, currentAccount
            )
        case let .contextError(message):
            return "google_user_service_context_error".localizeWithArguments(message)
        case let .inconsistentState(message):
            return "google_user_service_error_inconsistent_state".localizeWithArguments(message)
        case let .userNotAllowedAllNeededScopes(missingScopes, _):
            let scopesLabel = missingScopes.map(\.title).joined(separator: ", ")
            return "google_user_service_error_missing_scopes".localizeWithArguments(scopesLabel)
        }
    }
}

protocol GoogleAuthManagerType {
    func authorization(for email: String?) throws -> GTMAppAuth.AuthSession?
}

// this is here so that we don't have to include AppDelegate in test target
protocol AppDelegateGoogleSessionContainer {
    var googleAuthSession: OIDExternalUserAgentSession? { get set }
}

final class GoogleAuthManager: NSObject, GoogleAuthManagerType {

    var appDelegateGoogleSessionContainer: AppDelegateGoogleSessionContainer?

    init(
        appDelegateGoogleSessionContainer: AppDelegateGoogleSessionContainer? = nil
    ) {
        self.appDelegateGoogleSessionContainer = appDelegateGoogleSessionContainer
        super.init()
    }

    private enum Constants {
        static let index = "GTMAppAuthAuthorizerIndex"
    }

    lazy var logger = Logger.nested(in: Self.self, with: .userAppStart)

    private func idToken(for email: String?) throws -> String? {
        return try authorization(for: email)?.authState.lastTokenResponse?.idToken
    }

    func authorization(for email: String?) throws -> GTMAppAuth.AuthSession? {
        guard let email else {
            return nil
        }
        let keychainStore = GTMAppAuth.KeychainStore(itemName: Constants.index + email)
        // get authorization from keychain
        return try keychainStore.retrieveAuthSession()
    }

    private var authorizationConfiguration: OIDServiceConfiguration {
        if Bundle.shouldUseMockGmailApi {
            return OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "\(GeneralConstants.Mock.backendUrl)/o/oauth2/auth")!,
                tokenEndpoint: URL(string: "\(GeneralConstants.Mock.backendUrl)/token")!
            )
        } else {
            return GTMAppAuth.AuthSession.configurationForGoogle()
        }
    }
}

extension GoogleAuthManager {

    @MainActor
    func signIn(in viewController: UIViewController, scopes: [GoogleScope], userEmail: String? = nil) async throws -> SessionType {
        return try await withCheckedThrowingContinuation { continuation in
            let request = self.makeAuthorizationRequest(scopes: scopes, userEmail: userEmail)
            let googleDelegateSess = OIDAuthState.authState(
                byPresenting: request,
                presenting: viewController
            ) { [weak self] authState, authError in
                guard let self else { return }
                guard let authState else {
                    if let authError {
                        let error = self.parseSignInError(authError)
                        return continuation.resume(throwing: error)
                    } else {
                        let error = AppErr.unexpected("Shouldn't happen because received nil error and nil authState")
                        return continuation.resume(throwing: error)
                    }
                }
                Task {
                    do {
                        return try await continuation.resume(
                            returning: self.handleGoogleAuthStateResult(
                                authState,
                                scopes: scopes,
                                userEmail: userEmail
                            )
                        )
                    } catch {
                        return continuation.resume(throwing: error)
                    }
                }
            }
            self.appDelegateGoogleSessionContainer?.googleAuthSession = googleDelegateSess
        }
    }

    func signOut(user email: String) {
        DispatchQueue.main.async {
            self.appDelegateGoogleSessionContainer?.googleAuthSession = nil
            let keychainStore = GTMAppAuth.KeychainStore(itemName: Constants.index + email)
            try? keychainStore.removeAuthSession()
        }
    }

    private func parseSignInError(_ error: Error) -> Error {
        let nsError = error as NSError

        guard let underlyingError = nsError.userInfo["NSUnderlyingError"] as? NSError
        else {
            switch nsError.code {
            case -4: // login cancelled
                return GoogleAuthManagerError.cancelledAuthorization
            default:
                return error
            }
        }

        switch underlyingError.code {
        case 1:
            return GoogleAuthManagerError.cancelledAuthorization
        case 2:
            return GoogleAuthManagerError.contextError("A context wasn’t provided.")
        case 3:
            return GoogleAuthManagerError.contextError("The context was invalid.")
        default:
            return error
        }
    }

    private func handleGoogleAuthStateResult(
        _ authState: OIDAuthState,
        scopes: [GoogleScope],
        userEmail: String?
    ) async throws -> SessionType {
        let authorization = GTMAppAuth.AuthSession(authState: authState)

        guard let email = authorization.userEmail else {
            throw GoogleAuthManagerError.inconsistentState("Missing email")
        }
        if let userEmail, email != userEmail {
            throw GoogleAuthManagerError.wrongAccount(email, userEmail)
        }
        let missingScopes = checkMissingScopes(authState.scope, from: scopes)
        guard missingScopes.isEmpty else {
            throw GoogleAuthManagerError.userNotAllowedAllNeededScopes(
                missingScopes: missingScopes,
                email: authorization.userEmail
            )
        }
        try saveAuth(state: authState, for: email)
        guard let token = authState.lastTokenResponse?.accessToken else {
            throw GoogleAuthManagerError.inconsistentState("Missing token")
        }
        let user = try await self.fetchGoogleUser(with: authorization)
        return SessionType.google(email, name: user.name ?? "", token: token)
    }
}

// MARK: - Convenience
extension GoogleAuthManager {

    private func makeAuthorizationRequest(scopes: [GoogleScope], userEmail: String? = nil) -> OIDAuthorizationRequest {
        var additionalParameters = ["include_granted_scopes": "true"]

        if let userEmail {
            additionalParameters["login_hint"] = userEmail
        } else if Bundle.shouldUseMockGmailApi {
            additionalParameters["login_hint"] = GeneralConstants.Mock.userEmail
        }

        return OIDAuthorizationRequest(
            configuration: authorizationConfiguration,
            clientId: GeneralConstants.Gmail.clientID,
            scopes: scopes.map(\.value),
            redirectURL: GeneralConstants.Gmail.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: additionalParameters
        )
    }

    // save auth session to keychain
    private func saveAuth(state: OIDAuthState, for email: String) throws {
        state.stateChangeDelegate = self
        let authorization = GTMAppAuth.AuthSession(authState: state)
        let keychainStore = GTMAppAuth.KeychainStore(itemName: Constants.index + email)

        try keychainStore.save(authSession: authorization)
    }

    private func fetchGoogleUser(
        with authorization: GTMAppAuth.AuthSession
    ) async throws -> GTLROauth2_Userinfo {
        return try await withCheckedThrowingContinuation { continuation in
            let query = GTLROauth2Query_UserinfoGet.query()
            let authService = GTLROauth2Service()
            if Bundle.shouldUseMockGmailApi {
                authService.rootURLString = GeneralConstants.Mock.backendUrl + "/"
            }
            authService.authorizer = authorization
            authService.executeQuery(query) { _, data, error in
                if let error {
                    return continuation.resume(throwing: error)
                }
                guard let googleUser = data as? GTLROauth2_Userinfo else {
                    return continuation.resume(throwing: AppErr.cast("GTLROauth2_UserinfoResponse"))
                }
                return continuation.resume(returning: googleUser)
            }
        }
    }

    private func checkMissingScopes(_ scope: String?, from scopes: [GoogleScope]) -> [GoogleScope] {
        guard let allowedScopes = scope?.split(separator: " ").map(String.init),
              allowedScopes.isNotEmpty
        else { return scopes }
        return scopes.filter { !allowedScopes.contains($0.value) }
    }
}

// MARK: - Tokens
extension GoogleAuthManager {
    func getCachedOrRefreshedIdToken(minExpiryDuration: Double = 0, email: String?) async throws -> String {
        guard let idToken = try idToken(for: email) else { throw (IdTokenError.missingToken) }

        let decodedToken = try decode(idToken: idToken)

        guard decodedToken.expiryDuration > minExpiryDuration else {
            let (_, updatedToken) = try await performTokenRefresh(email: email)
            return updatedToken
        }

        return idToken
    }

    private func decode(idToken: String) throws -> IdToken {
        let components = idToken.components(separatedBy: ".")

        guard components.count == 3 else { throw (IdTokenError.invalidJWTFormat) }

        var decodedString = components[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while !decodedString.utf16.count.isMultiple(of: 4) {
            decodedString += "="
        }

        guard let decodedData = Data(base64Encoded: decodedString)
        else { throw (IdTokenError.invalidBase64EncodedData) }

        return try JSONDecoder().decode(IdToken.self, from: decodedData)
    }

    private func performTokenRefresh(email: String?) async throws -> (accessToken: String, idToken: String) {
        return try await withCheckedThrowingContinuation { continuation in
            let authorization = try? authorization(for: email)
            authorization?.authState.setNeedsTokenRefresh()
            authorization?.authState.performAction { accessToken, idToken, error in
                guard let accessToken, let idToken else {
                    let tokenError = error ?? AppErr.unexpected("Shouldn't happen because received nil error and nil token")
                    return continuation.resume(throwing: tokenError)
                }
                let result = (accessToken, idToken)
                return continuation.resume(with: .success(result))
            }
        }
    }
}

// MARK: - OIDAuthStateChangeDelegate
extension GoogleAuthManager: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        let authorization = GTMAppAuth.AuthSession(authState: state)
        guard let email = authorization.userEmail else {
            return
        }
        try? saveAuth(state: state, for: email)
    }
}
