//
//  ContactsServiceMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
@testable import FlowCrypt

class ContactsServiceMock: ContactsServiceType {
    var retrievePubKeyResult: ((String) -> (String))!
    func retrievePubKey(for email: String) -> String? {
        retrievePubKeyResult(email)
    }
    
    var searchContactResult: Result<Contact, Error>!
    func searchContact(with email: String) -> Promise<Contact> {
        Promise<Contact>.resolveAfter(with: searchContactResult)
    }
}
