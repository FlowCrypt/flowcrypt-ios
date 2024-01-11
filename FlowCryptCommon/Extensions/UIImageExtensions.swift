//
//  UIImageExtensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public extension UIImage {
    func tinted(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        color.set()
        withRenderingMode(.alwaysTemplate)
            .draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
