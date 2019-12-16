//
//  AppErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
 
/// Common Service which handle application errors
struct AppErrorHandler {
    static let `default` = AppErrorHandler(
        handlers: ErrorHandlerBuilder().handlers()
    )
    private let handlers: [ErrorHandlerType]
}

extension AppErrorHandler: ErrorHandlerType {
    @discardableResult
    func handle(error: ErrorLevel) -> Bool {

        let resut = handlers.map { $0.handle(error: error)}

        if !resut.contains(true) {
            assertionFailure("###Warning###\n\(#function)\nError \(error) should be handled")
            return false
        }

        return true
    }
}
