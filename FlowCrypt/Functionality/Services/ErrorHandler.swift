//
//  ErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension UIViewController {
    func handleCommon(error: Error) {
        let composedHandler = ComposedErrorHandler.shared
        let isErrorHandled = composedHandler.handle(error: error, for: self)

        if !isErrorHandled {
            assertionFailure("Error \(error) is not handled yet")
        }
    }
}

protocol ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool
}

/// This Handler contains array of all possible handlers
private struct ComposedErrorHandler: ErrorHandler {
    static let shared: ComposedErrorHandler = ComposedErrorHandler(
        handlers: [
            KeyServiceErrorHandler()
        ]
    )
    
    let handlers: [ErrorHandler]

    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let isErrorHandled = handlers.map { $0.handle(error: error, for: viewController) }

        // Error is handled by one of the handlers
        return isErrorHandled.contains(true)
    }
}
