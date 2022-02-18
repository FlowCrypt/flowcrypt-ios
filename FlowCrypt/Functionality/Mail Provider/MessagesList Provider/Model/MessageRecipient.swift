//
//  MessageRecipient.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 18/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageRecipient: RecipientBase, Hashable {
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
}

extension MessageRecipient {
    var displayName: String {
        name?.components(separatedBy: " ").first ??
        email.components(separatedBy: "@").first ??
        "unknown"
    }

    var rawString: (String?, String) { (name, email) }
}
