//
//  GoogleService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn
import Promises

protocol GoogleServiceType {
    func setUpAuthentication() throws
    func searchContacts(query: String) -> Promise<[String]>
    func shouldRenewToken(for scopes: [GoogleScope]) -> Bool
}

final class GoogleService {
    private enum Constants {
        static let scheme = "https"
        static let host = "www.google.com"
        static let searchPath = "/m8/feeds/contacts/default/thin"
    }

    private var instance = GIDSignIn.sharedInstance()

    private var token: String? {
        GIDSignIn.sharedInstance().currentUser.authentication.accessToken
    }

    private func components(for path: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = path
        return components
    }
}

extension GoogleService: GoogleServiceType {
    func shouldRenewToken(for scopes: [GoogleScope]) -> Bool {
        Set(scopes.map { $0.value })
            .isSubset(of: Set(instance?.scopes.compactMap { $0 as? String } ?? []))
    }

    func setUpAuthentication() throws {
        guard let googleSignIn = instance else { throw AppErr.general("Unexpected nil GIDSignIn") }
        googleSignIn.clientID = GeneralConstants.Gmail.clientID
        let scopes = GeneralConstants.Gmail.currentScope.map(\.value)
        googleSignIn.scopes = scopes
        // TODO: - ANTON !!!
//        googleSignIn.delegate = GoogleUserService.shared
    }

    func searchContacts(query: String) -> Promise<[String]> {
        guard let token = token else {
            assertionFailure("token should not be nil")
            return Promise(AppErr.unexpected("Missing token"))
        }

        var searchComponents = components(for: Constants.searchPath)
        searchComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "v", value: "3.0"),
            URLQueryItem(name: "alt", value: "json"),
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "start-index", value: "0")
        ]

        guard let url = searchComponents.url else {
            assertionFailure("Url should not be nil")
            return Promise(AppErr.unexpected("Missing url"))
        }

        return Promise<[String]> { () -> [String] in
            let response = try await(URLSession.shared.call(URLRequest(url: url)))
            let emails = try JSONDecoder().decode(GoogleContactsResponse.self, from: response.data).emails
            return emails
        }
    }
}
