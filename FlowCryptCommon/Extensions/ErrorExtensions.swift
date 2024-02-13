//
//  ErrorExtensions.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 04/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public extension Error {
    var errorMessage: String {
        switch self {
        case let self as CustomStringConvertible:
            return String(describing: self)
        default:
            return localizedDescription
        }
    }
}
