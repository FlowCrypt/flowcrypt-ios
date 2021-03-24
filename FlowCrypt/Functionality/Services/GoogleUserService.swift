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
    func signOut() -> Promise<Void>
    func signIn(in viewController: UIViewController) -> Promise<Void>
    func renewSession() -> Promise<Void>
}

final class GoogleUserService: NSObject {
    static let shared = GoogleUserService()

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
        case .oAuthGmail:
            if dataService.isLoggedIn {
                onLogin?()
            }
        case .password:
            assertionFailure("Implement this one")
        }
    }
}

extension GoogleUserService: UserServiceType {
    func renewSession() -> Promise<Void> {
//        let currentToken = GIDSignIn.sharedInstance()?.currentUser.authentication
        Promise<Void> { [weak self] resolve, reject in
            guard let self = self else { throw AppErr.nilSelf }
            DispatchQueue.main.async {
                self.onNewSession = { resolve(()) }
                self.onError = { error in reject(error) }
                self.googleManager.restorePreviousSignIn()
            }
        }
    }
    
    
    /*
     / Creates a GTMSessionFetcherService with the authorization.
     // Normally you would save this service object and re-use it for all REST API calls.
     GTMSessionFetcherService *fetcherService = [[GTMSessionFetcherService alloc] init];
     fetcherService.authorizer = self.authorization;

     // Creates a fetcher for the API call.
     NSURL *userinfoEndpoint = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v3/userinfo"];
     GTMSessionFetcher *fetcher = [fetcherService fetcherWithURL:userinfoEndpoint];
     [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
       // Checks for an error.
       if (error) {
         // OIDOAuthTokenErrorDomain indicates an issue with the authorization.
         if ([error.domain isEqual:OIDOAuthTokenErrorDomain]) {
           self.authorization = nil;
           NSLog(@"Authorization error during token refresh, clearing state. %@",
                 error);
         // Other errors are assumed transient.
         } else {
           NSLog(@"Transient error during token refresh. %@", error);
         }
         return;
       }

       // Parses the JSON response.
       NSError *jsonError = nil;
       id jsonDictionaryOrArray =
           [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

       // JSON error.
       if (jsonError) {
         NSLog(@"JSON decoding error %@", jsonError);
         return;
       }

       // Success response!
       NSLog(@"Success: %@", jsonDictionaryOrArray);
     }];
     
     
     */

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
                    resolve(())
                } else if let error = error {
                    // TODO: - ANTON - handle errors
                    print("^^ error \(error)")
                    reject(error)
                } else {
                    assertionFailure()
                }
            }
            
            // save current session state
            (UIApplication.shared.delegate as? AppDelegate)?.googleAuthSession = googleAuthSession
        }
    }
    
    // save auth session to keychain
    private func saveAuth(state: OIDAuthState) {
        // TODO: - ANTON - save index
        let authorization: GTMAppAuthFetcherAuthorization = GTMAppAuthFetcherAuthorization(authState: state)
        GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: "GTMAppAuthAuthorizerIndex")
        
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

// MARK: - Convenience
extension GoogleUserService {
    private func makeAuthorizationRequest() -> OIDAuthorizationRequest {
        OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: GeneralConstants.Gmail.clientID,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: GeneralConstants.Gmail.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
    }
}

extension GoogleUserService: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        saveAuth(state: state)
    }
}

extension GoogleUserService: GIDSignInDelegate {
    func sign(_: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            onError?(AppErr(error))
            return
        }
        guard let token = user.authentication.accessToken else {
            onError?(AppErr.general("could not save user or retrieve token"))
            return
        }

        // TODO: - ANTON
//        dataService.startFor(user: .google(user.profile.email, name: user.profile.name, token: token))
        onNewSession?()
        onLogin?()
    }

    func sign(_: GIDSignIn!, didDisconnectWith _: GIDGoogleUser!, withError _: Error!) {
        // will not wait until disconnected. errors ignored
        // TODO: - ANTON
//        dataService.logOutAndDestroyStorage()
        onLogOut?()
    }
}
