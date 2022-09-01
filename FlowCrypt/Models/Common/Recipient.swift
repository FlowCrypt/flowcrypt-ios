//
//  Recipient.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 17.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore
import GoogleAPIClientForREST_PeopleService

struct Recipient: RecipientBase {
    let email: String
    let name: String?
    var lastUsed: Date?
    var pubKeys: [PubKey] = []
}

extension Recipient {
    init(_ recipientObject: RecipientRealmObject) {
        self.email = recipientObject.email
        if let address = MCOAddress(nonEncodedRFC822String: recipientObject.name), address.displayName != nil {
            self.name = address.displayName
        } else {
            self.name = recipientObject.name
        }
        self.lastUsed = recipientObject.lastUsed
        self.pubKeys = recipientObject.pubKeys.map(PubKey.init)
    }

    init(_ string: String) {
        guard let address = MCOAddress(nonEncodedRFC822String: string) else {
            self.name = nil
            self.email = string
            return
        }
        self.name = address.displayName
        self.email = address.mailbox
    }

    init?(person: GTLRPeopleService_Person) {
        guard let email = person.emailAddresses?.first?.value else { return nil }

        self.email = email

        if let name = person.names?.first {
            self.name = name.displayName
        } else {
            self.name = nil
        }
    }

    init(recipient: RecipientBase) {
        self.email = recipient.email
        self.name = recipient.name
    }

    init(email: String, name: String? = nil) {
        self.email = email
        self.name = name
    }
}

extension Recipient {
    var rawString: (String?, String) { (name, email) }
}

extension Recipient: Comparable {
    static func < (lhs: Recipient, rhs: Recipient) -> Bool {
        guard let name1 = lhs.name else { return false }
        guard let name2 = rhs.name else { return true }
        return name1 < name2
    }
}

extension Recipient: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
}

extension Recipient: Equatable {
    static func == (lhs: Recipient, rhs: Recipient) -> Bool {
        lhs.email == rhs.email
    }
}
