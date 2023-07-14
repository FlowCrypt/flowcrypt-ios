//
//  CalendarExtension.swift
//  FlowCryptCommon
//
//  Created by Yevhen Kyivskyi on 01.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import Foundation

public extension Calendar {
    func isDateInCurrentYear(_ date: Date) -> Bool {
        self.isDate(date, equalTo: Date(), toGranularity: .year)
    }
}

public extension ASButtonNode {
    private func imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func setBackgroundColor(_ color: UIColor, forState controlState: UIControl.State) {
        setBackgroundImage(imageWithColor(color: color), for: controlState)
    }
}
