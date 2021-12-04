//
//  AppBundle.swift
//  FlowCrypt
//
//  Created by Tom on 03.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import Foundation

enum FlowCryptBundleType: String {
    case debug = "com.flowcrypt.as.ios.debug",
         consumer = "com.flowcrypt.as.ios.consumer",
         enterprise = "com.flowcrypt.as.ios.enterprise"
}

extension Bundle {

    static var flowCryptBundleType: FlowCryptBundleType {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return .debug }
        return FlowCryptBundleType(rawValue: bundleIdentifier) ?? .debug
    }
    
}
