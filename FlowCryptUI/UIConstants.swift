//
//  UIConstants.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 03.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import UIKit
import FlowCryptCommon

public extension UIEdgeInsets {
    static func deviceSpecificInsets(top: CGFloat, bottom: CGFloat) -> UIEdgeInsets {
        .init(top: top, left: .Insets.side, bottom: bottom, right: .Insets.side)
    }
    
    static var buttonInsets: UIEdgeInsets {
        let top: CGFloat = UIDevice.isIpad ? 16 : 8
        return UIEdgeInsets.deviceSpecificInsets(top: top, bottom: top)
    }
}

fileprivate extension CGFloat {
    enum Insets {
        fileprivate static var side: CGFloat {
            let minSide = Swift.min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            return UIDevice.isIpad ? (minSide * 0.2).rounded() : 24
        }
        
        fileprivate static var height: CGFloat {
            UIDevice.isIpad ? 24 : 8
        }
        
        fileprivate var minSide: CGFloat {
            UIDevice.isIpad ? 24 : 8
        }
    }
}
