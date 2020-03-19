//
//  UIColorExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension UIColor {
    static var main: UIColor {
        UIColor(named: "mainGreenColor")!
    }

    static var textColor: UIColor {
        UIColor(named: "additionalInfoLabelColor")!
    }

    static var mainTextColor: UIColor {
        UIColor(named: "mainTextColor")!
    }

    static var backgroundColor: UIColor {
        UIColor(named: "backgroundColor")!
    }

    static var dividerColor: UIColor {
        UIColor(named: "dividerColor")!
    }

    static var blueColor: UIColor {
        UIColor(red: 0, green: 120/255, blue: 1, alpha: 1)
    }
}
