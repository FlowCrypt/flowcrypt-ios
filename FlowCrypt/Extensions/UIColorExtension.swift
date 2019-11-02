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
        return UIColor(named: "mainGreenColor")!
    }

    static var textColor: UIColor {
        return UIColor(named: "additionalInfoLabelColor")!
    }

    static var blueColor: UIColor {
        return UIColor(red: 0, green: 120/255, blue: 1, alpha: 1)
    }
}
