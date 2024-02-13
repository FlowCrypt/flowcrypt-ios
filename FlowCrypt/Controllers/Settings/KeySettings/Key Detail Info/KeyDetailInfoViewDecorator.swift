//
//  KeyDetailInfoViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

struct KeyDetailInfoViewDecorator {
    let insets = UIEdgeInsets.deviceSpecificTextInsets(top: 4, bottom: 4)
    let dividerInsets = UIEdgeInsets.deviceSpecificTextInsets(top: 8, bottom: 8)

    func attributedTitle(
        for part: KeyDetailInfoViewController.Parts,
        keyId: KeyId,
        date: Date,
        user: String
    ) -> NSAttributedString {
        let title: String
        switch part {
        case .fingerprint:
            title = "key_settings_detail_fingerprint".localized + ":" + " "

            return title.attributed(.medium(16))
                + keyId.fingerprint.attributed(.regular(16), color: .gray)
        case .longId:
            title = "key_settings_detail_long".localized + ":" + " "
            return title.attributed(.medium(16))
                + keyId.longid.attributed(.regular(16))
        case .date:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            title = "key_settings_detail_date".localized + ":" + " "
            return title.attributed(.medium(16))
                + dateFormatter.string(from: date).attributed(.regular(16))
        case .users:
            title = "key_settings_detail_users".localized + ":" + " "
            return title.attributed(.medium(16))
                + user.attributed(.regular(16))
        case .separator:
            return NSAttributedString()
        }
    }
}
