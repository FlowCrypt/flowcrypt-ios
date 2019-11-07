//
//  UIImageExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension UIImage {
    func tinted(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        color.set()
        withRenderingMode(.alwaysTemplate)
            .draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
