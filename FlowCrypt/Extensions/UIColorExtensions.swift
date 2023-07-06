//
//  UIColorExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

// Uncomment for FlowCrypt application
public extension UIColor {
    convenience init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        if cString.count != 6 {
            return nil
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    static var main: UIColor {
        UIColor(r: 36, g: 156, b: 6, alpha: 1)
    }

    static var textColor: UIColor {
        colorFor(
            darkStyle: .white,
            lightStyle: .black
        )
    }

    static var warningColor: UIColor {
        UIColor(r: 194, g: 126, b: 35)
    }

    static var errorColor: UIColor {
        UIColor(r: 209, g: 72, b: 54)
    }

    static var mainTextColor: UIColor {
        colorFor(
            darkStyle: .white,
            lightStyle: .black
        )
    }

    static var backgroundColor: UIColor {
        colorFor(
            darkStyle: UIColor(r: 45, g: 44, b: 46, alpha: 1),
            lightStyle: .white
        )
    }

    static var dividerColor: UIColor {
        colorFor(
            darkStyle: UIColor(r: 102, g: 102, b: 102, alpha: 1),
            lightStyle: UIColor(r: 255, g: 255, b: 255, alpha: 0.1)
        )
    }

    static var mainTextUnreadColor: UIColor {
        colorFor(
            darkStyle: .white,
            lightStyle: .black
        )
    }

    static var activityIndicatorColor: UIColor {
        colorFor(
            darkStyle: .white,
            lightStyle: UIColor(r: 143, g: 142, b: 147, alpha: 1)
        )
    }

    static var blueColor: UIColor {
        UIColor(r: 0, g: 120, b: 255, alpha: 1)
    }
}

extension UIColor {
    convenience init(r: Int, g: Int, b: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat(r) / CGFloat(255.0),
            green: CGFloat(g) / CGFloat(255.0),
            blue: CGFloat(b) / CGFloat(255.0),
            alpha: alpha
        )
    }
}

public extension UIColor {
    static func colorFor(darkStyle: UIColor, lightStyle: UIColor) -> UIColor {
        switch UITraitCollection.current.userInterfaceStyle {
        case .dark: return darkStyle
        default: return lightStyle
        }
    }
}
