//
//  Error+Extension.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 04/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension Error {
    var errorMessage: String {
        switch self {
        case let self as CustomStringConvertible:
            return self.description
        default:
            return localizedDescription
        }
    }
}
