//
//  ContactsProvider.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 07.12.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import GoogleAPIClientForREST_PeopleService
import GTMAppAuth

enum ContactsProviderError: Error {
    /// People API response parsing
    case failedToParseData(Any?)
    /// Provider Error
    case providerError(Error)
}

class GoogleContactsProvider: ContactsProviderType {
    private var authorization: GTMAppAuthFetcherAuthorization?

    private var peopleService: GTLRPeopleServiceService {
        let service = GTLRPeopleServiceService()

        if Bundle.shouldUseMockGmailApi {
            service.rootURLString = GeneralConstants.Mock.backendUrl + "/"
        }

        service.authorizer = authorization
        return service
    }

    private enum QueryType {
        case contacts, other

        func query(searchString: String) -> GTLRPeopleServiceQuery {
            switch self {
            case .contacts:
                let query = GTLRPeopleServiceQuery_PeopleSearchContacts.query()
                query.readMask = readMask
                query.query = searchString
                return query
            case .other:
                let query = GTLRPeopleServiceQuery_OtherContactsSearch.query()
                query.readMask = readMask
                query.query = searchString
                return query
            }
        }

        var readMask: String {
            switch self {
            case .contacts, .other: return "names,emailAddresses"
            }
        }
    }

    init(authorization: GTMAppAuthFetcherAuthorization?) {
        self.authorization = authorization

        // Warmup query for google contacts cache
        runWarmupQuery()
    }

    func runWarmupQuery() {
        Task {
            _ = await searchContacts(query: "")
        }
    }

    func searchContacts(query: String) async -> [Recipient] {
        let contacts = await searchUserContacts(query: query, type: .contacts)
        let otherContacts = await searchUserContacts(query: query, type: .other)
        let allRecipients = (contacts + otherContacts)
            .map(Recipient.init)
            .unique()
            .sorted()
        return allRecipients
    }

    private func searchUserContacts(query: String, type: QueryType) async -> [Recipient] {
        let query = type.query(searchString: query)

        guard let emails = try? await perform(query: query) else { return [] }
        return emails
    }

    private func perform(query: GTLRPeopleServiceQuery) async throws -> [Recipient] {
        try await withCheckedThrowingContinuation { continuation in
            self.peopleService.executeQuery(query) { _, data, error in
                if let error {
                    return continuation.resume(throwing: ContactsProviderError.providerError(error))
                }

                guard let response = data as? GTLRPeopleService_SearchResponse else {
                    return continuation.resume(throwing: AppErr.cast("GTLRPeopleService_SearchResponse"))
                }

                guard let contacts = response.results else {
                    return continuation.resume(throwing: ContactsProviderError.failedToParseData(data))
                }

                let recipients = contacts.compactMap(\.person).compactMap(Recipient.init)
                return continuation.resume(returning: recipients)
            }
        }
    }
}
