//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

@available(*, deprecated, message: "Use FCError")
enum Errors: Error {
    case programmingError(String)
    case valueError(String)
}

enum FCError: Error {
    fileprivate static let authErrorCode = 5 // MCOErrorAuthentication
    case general
    case authentication
    case operation(Error)
}

extension FCError {
    init(_ error: Error) {
        if (error as NSError).code == FCError.authErrorCode {
            self = .authentication
        }
        self = .operation(error)
    }
}
