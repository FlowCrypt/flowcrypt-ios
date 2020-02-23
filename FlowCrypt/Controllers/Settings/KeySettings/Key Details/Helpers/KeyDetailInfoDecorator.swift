//
//  KeyDetailInfoDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptCommon

protocol KeyDetailInfoDecoratorType {
    var insets: UIEdgeInsets { get }
    var dividerInsets: UIEdgeInsets { get }

    func attributedTitle(
        for part: KeyDetailInfoViewController.Parts,
        keyId: KeyId,
        date: Date,
        user: String
    ) -> NSAttributedString
}

struct KeyDetailInfoDecorator: KeyDetailInfoDecoratorType {
    let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
    let dividerInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

    func attributedTitle(
        for part: KeyDetailInfoViewController.Parts,
        keyId: KeyId,
        date: Date,
        user: String
    ) -> NSAttributedString{
        let title: String
        switch part {
        case .keyWord:
            title = "key_settings_detail_key_words".localized + ":" + " "
            return title.attributed(.medium(16))
                + keyId.keywords.attributed(.regular(16), color: .main)
        case .fingerptint:
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
