//
//  GoogleScope.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 09/06/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum GoogleScope: CaseIterable {
    case userInfo, userEmail, mail, contacts, otherContacts

    var value: String {
        switch self {
        case .userInfo: return "https://www.googleapis.com/auth/userinfo.profile"
        case .userEmail: return "https://www.googleapis.com/auth/userinfo.email"
        case .mail: return "https://mail.google.com/"
        case .contacts: return "https://www.googleapis.com/auth/contacts"
        case .otherContacts: return "https://www.googleapis.com/auth/contacts.other.readonly"
        }
    }
}

extension GoogleScope {
    var title: String {
        switch self {
        case .userInfo:
            return "User Info"
        case .userEmail:
            return "User Email"
        case .mail:
            return "Gmail"
        case .contacts:
            return "Contacts"
        case .otherContacts:
            return "Other Contacts"
        }
    }
}
