//
//  AppErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
 
/// Common Service which handle application errors
final class AppErrorHandler {
    static let `default` = AppErrorHandler(
        handlers: ErrorHandlerBuilder().handlers()
    )
    private let handlers: [ErrorHandlerType]

    private init(handlers: [ErrorHandlerType]) {
        self.handlers = handlers
    }
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


// TODO: - App Error
// Workaround to not inject AppErrorHandler to every ViewController.
// Should be updated with DI
extension UIViewController {
    private static var _appErrorHandler = [String:AppErrorHandler]()

    var appErrorHandler: AppErrorHandler {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIViewController._appErrorHandler[tmpAddress] ?? AppErrorHandler.default
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIViewController._appErrorHandler[tmpAddress] = newValue
        }
    }
}

