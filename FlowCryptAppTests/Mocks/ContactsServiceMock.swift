//
//  ContactsServiceMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

final class ContactsServiceMock: ContactsServiceType {
    var retrievePubKeysResult: ((String) -> ([String]))!
    func retrievePubKeys(for email: String) -> [String] {
        retrievePubKeysResult(email)
    }

    var searchContactResult: Result<RecipientWithSortedPubKeys, Error>!
    func searchContact(with email: String) async throws -> RecipientWithSortedPubKeys {
        switch searchContactResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        default:
            fatalError()
        }
    }
    func searchContacts(query: String) -> [String] { [] }

    func removePubKey(with fingerprint: String, for email: String) {}
}
