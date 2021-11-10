//
//  GoogleAuthStateHandlerProtocol.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 11/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import AppAuthCore
import UIKit
import Promises
import FlowCryptCommon
import GTMAppAuth

protocol GoogleAuthStateHandlerProtocol {
    func authStateByPresentingAuthorizationRequest(
        authorizationRequest: OIDAuthorizationRequest,
        presentingViewController: UIViewController,
        callback: OIDAuthStateAuthorizationCallback
    ) -> OIDExternalUserAgentSession
}

protocol GoogleUserServiceType {
    var authorization: GTMAppAuthFetcherAuthorization? { get }
    func renewSession() -> Promise<Void>
}

final class GoogleUserService: NSObject, GoogleUserServiceType {

    private enum Constants {
        static let index = "GTMAppAuthAuthorizerIndex"
    }
    lazy var logger = Logger.nested(in: Self.self, with: .userAppStart)

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

    var currentUserEmail: String? {
        DataService.shared.email
    }

    private func getAuthorizationForCurrentUser() -> GTMAppAuthFetcherAuthorization? {
        // get active user
        guard let email = currentUserEmail else {
            return nil
        }
        // get authorization from keychain
        return GTMAppAuthFetcherAuthorization(fromKeychainForName: Constants.index + email)
    }

    func renewSession() -> Promise<Void> {
        // GTMAppAuth should renew session via OIDAuthStateChangeDelegate
        Promise<Void> { [weak self] resolve, _ in
            self?.logger.logInfo("Renew session for google user")
            resolve(())
        }
    }
}
