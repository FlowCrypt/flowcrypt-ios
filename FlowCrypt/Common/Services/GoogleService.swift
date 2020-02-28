//
//  GoogleService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 28/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn

protocol GoogleServiceType {
    func setUpAuthentication() throws
    func searchContacts(query: String)
}

final class GoogleService {
    private enum Constants {
        static let scheme = "https"
        static let host = "www.google.com"

        static let searchPath = "/m8/feeds/contacts/default/thin"
    }

    enum Scope: CaseIterable {
        case userInfo, mail, feed, contacts
        var value: String {
            switch self {
            case .userInfo: return "https://www.googleapis.com/auth/userinfo.profile"
            case .mail: return "https://mail.google.com/"
            case .feed: return "https://www.google.com/m8/feeds"
            case .contacts: return "https://www.googleapis.com/auth/contacts.readonly"
            }
        }
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
    func shouldRenewToken(for scopes: [Scope]) -> Bool {
        Set(scopes.map {$0.value}).isSubset(
            of: Set(instance?.scopes.compactMap { $0 as? String } ?? [])
        )
    }

    func setUpAuthentication() throws {
        guard let googleSignIn = instance else { throw AppErr.general("Unexpected nil GIDSignIn") }
        googleSignIn.clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        googleSignIn.scopes = Scope.allCases.compactMap { $0.value }
        googleSignIn.delegate = UserService.shared
    }

    func searchContacts(query: String) {
        guard let token = token else {
            assertionFailure("token should not be nil")
            return
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
            return
        }

        URLSession.shared.call(URLRequest(url: url))
            .then(on: .main) { res in
                do {
                    let encoded = try JSONDecoder().decode(Feed.self, from: res.data)
                    print(encoded)
//                    print(String(decoding: encoded, as: ContactsResponse.self))
                } catch {
                    print(error)
                }

        }.catch(on: .main) { error in
            print("^^ \(error)")
        }
    }
}

struct Feed: Codable {
    let feed: Entry

    struct Entry: Codable {

    }
}

struct EmailEntry: Codable {
//    let address: String
}

struct Adress: Codable {
    let address: String
}


// compose_enable_search
