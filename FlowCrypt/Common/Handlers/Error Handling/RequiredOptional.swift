//
//  RequiredOptional.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension Optional {
    func orThrow(_ errorExpression: @autoclosure () -> Error) throws -> Wrapped {
        guard let value = self else {
            throw errorExpression()
        }
        return value
    }
}

extension Optional {
    var required: Wrapped? {
        guard let value = try? self.orThrow(DataError.userRequired) else {
            AppErrorHandler.default.handle(error: .dataError(DataError.userRequired))
            return nil
        }
        return value
    }
}
