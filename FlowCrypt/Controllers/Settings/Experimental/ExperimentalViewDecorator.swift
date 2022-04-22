//
//  ExperimentalViewDecorator.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/22/22.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct ExperimentalViewDecorator {
    let sceneTitle = "experimental_title".localized
    let insets = UIEdgeInsets.deviceSpecificTextInsets(top: 16, bottom: 16)

    func attributedSetting(_ title: String) -> NSAttributedString {
        title.attributed(.regular(16), color: .mainTextColor)
    }
}
