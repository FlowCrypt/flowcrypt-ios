//
//  ContactsServiceMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises
@testable import FlowCrypt

class ContactsServiceMock: ContactsServiceType {
    var retrievePubKeysResult: ((String) -> ([String]))!
    func retrievePubKeys(for email: String) -> [String] {
        retrievePubKeysResult(email)
    }
    
    var searchContactResult: Result<RecipientWithPubKeys, Error>!
    func searchContact(with email: String) -> Promise<RecipientWithPubKeys> {
        Promise<RecipientWithPubKeys>.resolveAfter(with: searchContactResult)
    }

    func removePubKey(with fingerprint: String, for email: String) {}
}
