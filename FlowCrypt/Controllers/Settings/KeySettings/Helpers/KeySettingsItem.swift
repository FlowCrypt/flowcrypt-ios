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
    let createdDate: String
    let keywords: String
    let publicInfo: String
    let fingerPrint: String
    let longId: String
    let user: String
}

// TODO: - Anton
extension KeySettingsItem {
    init?(_ core: CoreRes.ParseKeys) {
        guard let details = core.keyDetails.first else { return nil }
        self.title = details.private ?? "key_settings_no_private".localized
        return nil
    }
}
