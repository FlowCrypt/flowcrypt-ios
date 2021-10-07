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
        static let host = "people.googleapis.com"
        static let searchPath = "/v1/people:searchContacts"
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

        // TODO: Add warmup query
        var searchComponents = components(for: Constants.searchPath)
        searchComponents.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "readMask", value: "names,emailAddresses")
        ]

        guard let url = searchComponents.url else {
            assertionFailure("Url should not be nil")
            return Promise(AppErr.unexpected("Missing url"))
        }

        let headers = [URLHeader(value: "Bearer \(token)", httpHeaderField: "Authorization"),
                       URLHeader(value: "application/json; charset=UTF-8", httpHeaderField: "Content-type")]
        let request = URLRequest.urlRequest(with: url.absoluteString, headers: headers)

        return Promise<[String]> { () -> [String] in
            let response = try awaitPromise(URLSession.shared.call(request))
            let emails = try JSONDecoder().decode(GoogleContactsResponse.self, from: response.data).emails
            return emails
        }
    }
}
