//
//  ContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.03.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Promises
import GoogleAPIClientForREST_PeopleService

protocol CloudContactsProvider {
    func searchContacts(query: String) -> Promise<[String]>
}

enum CloudContactsProviderError: Error {
    /// People API response parsing
    case failedToParseData(Any?)
    /// Provider Error
    case providerError(Error)
}

final class UserContactsProvider {
    private let logger = Logger.nested("UserContactsProvider")
    private let userService: GoogleUserServiceType
    private var peopleService: GTLRPeopleServiceService {
        let service = GTLRPeopleServiceService()

        if userService.authorization == nil {
            logger.logWarning("authorization for current user is nil")
        }

        service.authorizer = userService.authorization
        return service
    }

    init(userService: GoogleUserServiceType = GoogleUserService()) {
        self.userService = userService
        
        // Warmup query for contacts cache
        _ = self.searchContacts(query: "")
    }
}

extension UserContactsProvider: CloudContactsProvider {
    func searchContacts(query: String) -> Promise<[String]> {
        let searchQuery = GTLRPeopleServiceQuery_PeopleSearchContacts.query()
        searchQuery.readMask = "names,emailAddresses"
        searchQuery.query = query

        return Promise<[String]> { resolve, reject in
            self.peopleService.executeQuery(searchQuery) { _, data, error in
                if let error = error {
                    return reject(CloudContactsProviderError.providerError(error))
                }

                guard let response = data as? GTLRPeopleService_SearchResponse else {
                    return reject(AppErr.cast("GTLRPeopleService_SearchResponse"))
                }

                guard let contacts = response.results else {
                    return reject(CloudContactsProviderError.failedToParseData(data))
                }

                let emails = contacts
                    .compactMap { $0.person?.emailAddresses }
                    .flatMap { $0 }
                    .compactMap { $0.value }

                resolve(emails)
            }
        }
    }
}
