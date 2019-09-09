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
    case general
    case authentication
    case connection
    case operation(Error)
}

extension FCError {
    init(_ error: Error) {
        let code = (error as NSError).code
        switch code {
        case MCOErrorCode.authentication.rawValue:
            self = .authentication
        case MCOErrorCode.connection.rawValue,
             MCOErrorCode.tlsNotAvailable.rawValue,
             MCOErrorCode.connection.rawValue:
            self = .connection
        default:
            self = .operation(error)
        }
    }
}
