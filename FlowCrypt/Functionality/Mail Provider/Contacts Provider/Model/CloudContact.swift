//
//  CloudContact.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_PeopleService

struct CloudContact: RecipientBase, Hashable {
    let email: String
    let name: String?
}

extension CloudContact {
    init?(person: GTLRPeopleService_Person) {
        guard let email = person.emailAddresses?.first?.value else { return nil }

        self.email = email

        if let name = person.names?.first {
            self.name = [name.givenName, name.familyName].compactMap { $0 }.joined(separator: " ")
        } else {
            self.name = nil
        }
    }
}
