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
    case operation(Error)
}

extension FCError {
    init(_ error: Error) {
        if (error as NSError).code == Imap.Err.authentication.rawValue {
            self = .authentication
        }
        self = .operation(error)
    }
}
