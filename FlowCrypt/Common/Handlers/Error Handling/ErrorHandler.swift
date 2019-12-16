//
//  ErrorHandlerType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol ErrorHandlerType {
    func handle(error level: ErrorLevel) -> Bool
}

protocol ErrorHandlerBuilderType {
    func handlers() -> [ErrorHandlerType]
}

struct ErrorHandlerBuilder: ErrorHandlerBuilderType {
    func handlers() -> [ErrorHandlerType] {
        [ViewControllerErrorHandler(), DataErrorHandler()]
    }
}
