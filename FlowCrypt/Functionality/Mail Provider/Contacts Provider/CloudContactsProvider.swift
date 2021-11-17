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
    var isContactsScopeEnabled: Bool { get }
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
    private let userService: GoogleUserServiceType & UserServiceType
    private var peopleService: GTLRPeopleServiceService {
        let service = GTLRPeopleServiceService()

        if userService.authorization == nil {
            logger.logWarning("authorization for current user is nil")
        }

        service.authorizer = userService.authorization
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
            case .contacts, .other: return "emailAddresses"
            }
        }
    }

    var isContactsScopeEnabled: Bool {
        guard let currentScopeString = userService.authorization?.authState.scope else { return false }
        let currentScope = currentScopeString.split(separator: ",").map(String.init)
        let contactsScope = GeneralConstants.Gmail.contactsScope.map(\.value)
        return contactsScope.allSatisfy(currentScope.contains)
    }

    init(userService: GoogleUserServiceType & UserServiceType = GoogleUserService()) {
        self.userService = userService

        runWarmupQuery()
    }

    private func runWarmupQuery() {
        Task {
            // Warmup query for google contacts cache
            _ = await searchContacts(query: "")
        }
    }
}

extension UserContactsProvider: CloudContactsProvider {
    func searchContacts(query: String) async -> [String] {
        guard isContactsScopeEnabled else { return [] }
        let contacts = await searchUserContacts(query: query, type: .contacts)
        let otherContacts = await searchUserContacts(query: query, type: .other)
        let emails = Set(contacts + otherContacts)
        return Array(emails).sorted(by: >)
    }
}

extension UserContactsProvider {
    private func searchUserContacts(query: String, type: QueryType) async -> [String] {
        let query = type.query(searchString: query)

        guard let emails = try? await perform(query: query) else { return [] }
        return emails
    }

    private func perform(query: GTLRPeopleServiceQuery) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            self.peopleService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: CloudContactsProviderError.providerError(error))
                }

                guard let response = data as? GTLRPeopleService_SearchResponse else {
                    return continuation.resume(throwing: AppErr.cast("GTLRPeopleService_SearchResponse"))
                }

                guard let contacts = response.results else {
                    return continuation.resume(throwing: CloudContactsProviderError.failedToParseData(data))
                }

                let emails = contacts
                    .compactMap { $0.person?.emailAddresses }
                    .flatMap { $0 }
                    .compactMap { $0.value }

                return continuation.resume(returning: emails)
            }
        }
    }
}
