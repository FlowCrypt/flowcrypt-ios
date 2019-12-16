//
//  RequiredOptional.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension Optional {

    /// Optional property that shoul be required inside the application
    var required: Wrapped? {
        switch self {
        case .some(let value):
            return value
        default:
            AppErrorHandler.default.handle(error: .dataError(DataError.userRequired))
            return nil
        }
    }
}
