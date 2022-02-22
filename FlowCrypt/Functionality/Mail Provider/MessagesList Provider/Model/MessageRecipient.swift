//
//  MessageRecipient.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 18/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_PeopleService

struct MessageRecipient: RecipientBase {
    let name: String?
    let email: String

    init(_ string: String) {
        let parts = string.components(separatedBy: " ")

        guard parts.count > 1, let email = parts.last else {
            self.name = nil
            self.email = string
            return
        }

        self.email = email.filter { !["<", ">"].contains($0) }
        let name = string
            .replacingOccurrences(of: email, with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespaces)
        self.name = name == self.email ? nil : name
    }

    init?(person: GTLRPeopleService_Person) {
        guard let email = person.emailAddresses?.first?.value else { return nil }

        self.email = email

        if let name = person.names?.first {
            self.name = [name.givenName, name.familyName].compactMap { $0 }.joined(separator: " ")
        } else {
            self.name = nil
        }
    }

    init(recipient: RecipientBase) {
        self.name = recipient.name
        self.email = recipient.email
    }
}

extension MessageRecipient {
    var rawString: (String?, String) { (name, email) }
}

extension MessageRecipient: Comparable {
    static func < (lhs: MessageRecipient, rhs: MessageRecipient) -> Bool {
        guard let name1 = lhs.name else { return false }
        guard let name2 = rhs.name else { return true }
        return name1 < name2
    }
}

extension MessageRecipient: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
}

extension MessageRecipient: Equatable {
    static func == (lhs: MessageRecipient, rhs: MessageRecipient) -> Bool {
        lhs.email == rhs.email
    }
}
