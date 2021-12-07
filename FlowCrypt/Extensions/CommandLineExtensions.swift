//
//  CommandLineExtensions.swift
//  FlowCrypt
//
//  Created by Tom on 03.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//



import Foundation

extension CommandLine {
    
    static func isDebugBundleWithArgument(_ argument: String) -> Bool {
        guard Bundle.flowCryptBundleType == .debug else { return false }
        return CommandLine.arguments.contains(argument)
    }
    
}
