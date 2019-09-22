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
    case message(String) // todo tom: should be renamed to something more meaningful, eg programmingError or valueError
    case missingWeakRef
}

extension FCError: Equatable {
    static func == (lhs: FCError, rhs: FCError) -> Bool {
        switch (lhs, rhs) {
        case (.general, .general): return true
        case (.authentication, .authentication): return true
        case (.connection, .connection): return true
        case (.operation, .operation): return true
        default: return false
        }
    }
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
