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

    var fetchContactResult: Result<RecipientWithSortedPubKeys, Error>!
    func fetch(contact: Recipient) async throws -> RecipientWithSortedPubKeys {
        switch fetchContactResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        default:
            fatalError()
        }
    }

    var findLocalContactResult: Result<RecipientWithSortedPubKeys, Error>!
    func findLocalContact(with email: String) async throws -> RecipientWithSortedPubKeys? {
        switch findLocalContactResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        default:
            fatalError()
        }
    }

    func searchLocalContacts(query: String) throws -> [RecipientBase] { [] }

    func removePubKey(with fingerprint: String, for email: String) {}
}
