//
//  UIColorExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

// Uncomment for FlowCrypt application
extension UIColor {
    static var main: UIColor {
        UIColor(r: 36, g: 156, b: 6, alpha: 1)
    }

    static var textColor: UIColor {
        UIColor(r: 57, g: 57, b: 57, alpha: 1)
    }

    static var mainTextColor: UIColor {
        UIColor.colorFor(
            darkStyle: .white,
            lightStyle: .black
        )
    }

    static var backgroundColor: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor(r: 45, g: 44, b: 46, alpha: 1),
            lightStyle: .white
        )
    }

    static var dividerColor: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor(r: 102, g: 102, b: 102, alpha: 1),
            lightStyle: UIColor(r: 255, g: 255, b: 255, alpha: 0.1)
        )
    }

    static var mainTextUnreadColor: UIColor {
        UIColor.colorFor(
            darkStyle: .white,
            lightStyle: .black
        )
    }

    static var activityIndicatorColor: UIColor {
        UIColor.colorFor(
            darkStyle: .white,
            lightStyle: UIColor(r: 143, g: 142, b: 147, alpha: 1)
        )
    }

    static var blueColor: UIColor {
        UIColor(r: 0, g: 120, b: 255, alpha: 1)
    }
}

extension UIColor {
    convenience init(r: Int, g: Int, b: Int, alpha: CGFloat) {
        self.init(
            red: CGFloat(r)/CGFloat(255.0),
            green: CGFloat(g)/CGFloat(255.0),
            blue: CGFloat(b)/CGFloat(255.0),
            alpha: alpha
        )
    }
}

// Uncomment for FlowCryptUIApplication
//extension UIColor {
//    static var main: UIColor {
//        .green
//    }
//
//    static var textColor: UIColor {
//        .darkGray
//    }
//
//    static var mainTextColor: UIColor {
//        .black
//    }
//
//    static var backgroundColor: UIColor {
//        .white
//    }
//
//    static var dividerColor: UIColor {
//        .black
//    }
//
//    static var mainTextUnreadColor: UIColor {
//        .black
//    }
//
//    static var activityIndicatorColor: UIColor {
//        .black
//    }
//
//    static var blueColor: UIColor {
//        .blue
//    }
//}
