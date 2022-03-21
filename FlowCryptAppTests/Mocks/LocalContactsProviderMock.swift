//
//  LocalContactsProviderMock.swift
//  FlowCryptAppTests
//
//  Created by Ioan Moldovan on 3/17/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

final class LocalContactsProviderMock: LocalContactsProviderType {

    func searchRecipient(with email: String) async throws -> RecipientWithSortedPubKeys? { nil }

    func searchEmails(query: String) throws -> [String] { [] }

    func save(recipient: RecipientWithSortedPubKeys) throws {}

    func remove(recipient: RecipientWithSortedPubKeys) throws {}

    func updateKeys(for recipient: RecipientWithSortedPubKeys) throws {}

    func getAllRecipients() async throws -> [RecipientWithSortedPubKeys] { [] }

    var retrievePubKeysResult: ((String) -> ([String]))!
    func retrievePubKeys(for email: String) -> [String] {
        retrievePubKeysResult(email)
    }

    func removePubKey(with fingerprint: String, for email: String) {}
}
