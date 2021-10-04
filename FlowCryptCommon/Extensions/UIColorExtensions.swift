//
//  UIColorExtension.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 20/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public extension UIColor {
    static func colorFor(darkStyle: UIColor, lightStyle: UIColor) -> UIColor {
        switch UITraitCollection.current.userInterfaceStyle {
        case .dark: return darkStyle
        default: return lightStyle
        }
    }
}
