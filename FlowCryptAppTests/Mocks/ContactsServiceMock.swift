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
    
    var searchContactResult: Result<Contact, Error>!
    func searchContact(with email: String) -> Promise<Contact> {
        Promise<Contact>.resolveAfter(with: searchContactResult)
    }

    func remove(pubKey: String, for email: String) {}
}
