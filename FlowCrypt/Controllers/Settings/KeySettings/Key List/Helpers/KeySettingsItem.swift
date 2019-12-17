//
//  KeySettingsItem.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct KeySettingsItem {
    let title: String
    let createdDate: Date
    let details: [KeyId]
    let publicKey: String
    let users: String
}

extension KeySettingsItem {
    init?(_ details: KeyDetails) {
        self.title = details.private ?? "key_settings_no_private".localized
        self.createdDate = Date(timeIntervalSince1970: TimeInterval(details.created))
        self.details = details.ids
        self.publicKey = details.public
        self.users = details.users.reduce("") { (result, newValue) in
            var new = result
            new.append(newValue)
            new.append(" ")
            return new
        }
        print(self.users)
    }
}
