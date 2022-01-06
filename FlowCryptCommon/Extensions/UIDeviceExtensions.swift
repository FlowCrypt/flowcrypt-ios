//
//  UIDeviceExtensions.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 05.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import UIKit

extension UIDevice {
    public static var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public static var isIphone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
