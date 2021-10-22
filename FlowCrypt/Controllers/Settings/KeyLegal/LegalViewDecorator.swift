//
//  LegalViewDecorator.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 21.10.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol LegalViewDecoratorType {
    var sceneTitle: String { get }
    var insets: UIEdgeInsets { get }
    func attributedSetting(_ title: String) -> NSAttributedString
}

struct LegalViewDecorator: LegalViewDecoratorType {
    let sceneTitle = "settings_screen_legal".localized
    let insets = UIEdgeInsets.side(16)

    func attributedSetting(_ title: String) -> NSAttributedString {
        title.attributed(.regular(16), color: .mainTextColor)
    }
}
