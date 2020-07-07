//
//  SettingsViewControllerDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol SettingsViewDecoratorType {
    var sceneTitle: String { get }
    var insets: UIEdgeInsets { get }
    func attributedSetting(_ title: String) -> NSAttributedString
}

struct SettingsViewDecorator: SettingsViewDecoratorType {
    let sceneTitle = "settings_screen_title".localized
    let insets = UIEdgeInsets.side(16)

    func attributedSetting(_ title: String) -> NSAttributedString {
        title.attributed(.regular(16), color: .mainTextColor)
    }
}
