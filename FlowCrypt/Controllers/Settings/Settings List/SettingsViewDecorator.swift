//
//  SettingsViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct SettingsViewDecorator {
    let sceneTitle = "settings_screen_title".localized
    let insets = UIEdgeInsets.deviceSpecificTextInsets(top: 16, bottom: 16)

    func attributedSetting(_ title: String) -> NSAttributedString {
        title.attributed(.regular(16), color: .mainTextColor)
    }
}
