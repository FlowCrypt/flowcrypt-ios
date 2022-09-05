//
//  RecipientBase.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 17/02/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol RecipientBase {
    var email: String { get }
    var name: String? { get }
}

extension RecipientBase {
    var formatted: String {
        guard let name = name else { return email }
        return "\(name) <\(email)>"
    }

    var shortName: String {
        name?.components(separatedBy: " ").first ??
        email.components(separatedBy: "@").first ??
        "unknown"
    }

    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        return email
    }
}
