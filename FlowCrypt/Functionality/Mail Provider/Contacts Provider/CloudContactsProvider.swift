//
//  ContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.03.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

protocol CloudContactsProvider {
    func searchContacts(query: String) -> Promise<[String]>
}

final class UserContactsProvider {
    private enum Constants {
        static let scheme = "https"
        static let host = "www.google.com"
        static let searchPath = "/m8/feeds/contacts/default/thin"
    }

    private let dataService: DataService

    private var token: String? {
        dataService.token
    }

    init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    private func components(for path: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = path
        return components
    }
}

extension UserContactsProvider: CloudContactsProvider {
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
            let response = try awaitPromise(URLSession.shared.call(URLRequest(url: url)))
            let emails = try JSONDecoder().decode(GoogleContactsResponse.self, from: response.data).emails
            return emails
        }
    }
}
