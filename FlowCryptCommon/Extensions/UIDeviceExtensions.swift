//
//  UIDeviceExtensions.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 05.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public extension UIDevice {
    static var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isIphone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
