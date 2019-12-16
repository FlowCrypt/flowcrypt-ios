//
//  DataErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum DataError: Error {
    case userRequired
}

struct DataErrorHandler: ErrorHandlerType {
    func handle(error level: ErrorLevel) -> Bool {
        guard case let .dataError(error) = level else { return false }

        switch error {
        case DataError.userRequired:
            print("Show User login flow")
        default:
            return false
        }

        return true
    }
}
