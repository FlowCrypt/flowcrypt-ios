//
//  Device.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 03.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import UIKit
import Foundation

public struct Device {
    public static var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public static var isIphone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    public static var minDimension: CGFloat {
        min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    }
}

fileprivate extension CGFloat {
    enum Insets {
        fileprivate static var side: CGFloat {
            Device.isIpad ? (Device.minDimension * 0.2).rounded() : 24
        }
        
        fileprivate static var height: CGFloat {
            Device.isIpad ? 24 : 8
        }
        
        fileprivate var minSide: CGFloat {
            Device.isIpad ? 24 : 8
        }
    }
}

public extension UIEdgeInsets {
    static func deviceSpecificInsets(top: CGFloat, bottom: CGFloat) -> UIEdgeInsets {
        .init(top: top, left: .Insets.side, bottom: bottom, right: .Insets.side)
    }
    
    static var buttonInsets: UIEdgeInsets {
        let top: CGFloat = Device.isIpad ? 16 : 8
        return UIEdgeInsets.deviceSpecificInsets(top: top, bottom: top)
    }
}
