//
//  Extensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/30/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public extension UIEdgeInsets {
    static var side: (CGFloat) -> UIEdgeInsets {
        { side in UIEdgeInsets(top: side, left: side, bottom: side, right: side) }
    }

    var width: CGFloat {
        left + right
    }

    var height: CGFloat {
        top + bottom
    }
}
