//
//  KeySettingsItemDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

extension KeyDetailViewController.Parts {
    var isDescription: Bool {
        guard case .description = self else { return false }
        return true
    }

    var isPrivateKey: Bool {
        guard case .privateInfo = self else { return false }
        return true
    }
}

struct KeyDetailViewDecorator {
    let titleInsets = UIEdgeInsets.deviceSpecificTextInsets(top: 16, bottom: 16)
    let buttonInsets = UIEdgeInsets.buttonInsets

    func attributedTitle(for keyDetailPart: KeyDetailViewController.Parts) -> NSAttributedString {
        let title: String
        switch keyDetailPart {
        case .description: title = "key_settings_subtitle".localized
        case .publicInfo: title = "key_settings_detail_show_public".localized
        case .copy: title = "key_settings_detail_copy".localized
        case .keyDetails: title = "key_settings_detail_show_details".localized
        case .save: title = "key_settings_detail_save".localized
        case .privateInfo: title = "key_settings_detail_show_private_title".localized
        }

        if keyDetailPart.isDescription {
            return title.attributed(.bold(16), color: .gray)
        } else {
            return title.attributed(.bold(16), color: .white)
        }
    }

    func buttonColor(for keyDetailPart: KeyDetailViewController.Parts) -> UIColor {
        keyDetailPart.isPrivateKey ? .red : .main
    }
}
