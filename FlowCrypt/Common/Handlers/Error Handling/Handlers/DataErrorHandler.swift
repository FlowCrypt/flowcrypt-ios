//
//  DataErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct DataErrorHandler: ErrorHandlerType {
    func handle(error level: ErrorLevel) -> Bool {
        guard case let .dataError(error) = level else { return false }


        return true
    }
}
