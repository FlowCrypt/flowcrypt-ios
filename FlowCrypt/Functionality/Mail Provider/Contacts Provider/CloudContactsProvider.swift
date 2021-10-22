//
//  ContactsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.03.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST_PeopleService

protocol CloudContactsProvider {
    func searchContacts(query: String) async throws -> [String]
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

        runWarmupQuery()
    }

    private func runWarmupQuery() {
        Task {
            // Warmup query for google contacts cache
            _ = try? await searchContacts(query: "")
        }
    }
}

extension UserContactsProvider: CloudContactsProvider {
    func searchContacts(query: String) async throws -> [String] {
        let searchQuery = GTLRPeopleServiceQuery_PeopleSearchContacts.query()
        searchQuery.readMask = "names,emailAddresses"
        searchQuery.query = query

        return try await withCheckedThrowingContinuation { continuation in
            self.peopleService.executeQuery(searchQuery) { _, data, error in
                if let error = error {
                    continuation.resume(throwing: CloudContactsProviderError.providerError(error))
                    return
                }

                guard let response = data as? GTLRPeopleService_SearchResponse else {
                    continuation.resume(throwing: AppErr.cast("GTLRPeopleService_SearchResponse"))
                    return
                }

                guard let contacts = response.results else {
                    continuation.resume(throwing: CloudContactsProviderError.failedToParseData(data))
                    return
                }

                let emails = contacts
                    .compactMap { $0.person?.emailAddresses }
                    .flatMap { $0 }
                    .compactMap { $0.value }

                continuation.resume(returning: emails)
            }
        }
    }
}
