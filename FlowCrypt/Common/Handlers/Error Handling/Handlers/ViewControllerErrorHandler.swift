//
//  ViewControllerErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct ViewControllerErrorHandler: ErrorHandlerType {
    func handle(error level: ErrorLevel) -> Bool {
        guard case let .viewController(error, viewController) = level else { return false }


        return true
    }
}
