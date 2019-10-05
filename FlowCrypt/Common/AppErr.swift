//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum AppErr: Error {
    // network
    case authentication
    case connection
    case operation(Error)
    // code
    case nilSelf // guard let self = self else { throw AppErr.nilSelf }
    case value(String) // wrong value passed into a function
    case unexpected(String) // we did not expect to ever see this error in practice
    case cast(String) // something as? Something is unexpectedly nil
    // all others
    case user(String) // user error, useful to throw from Promises
    case silentAbort // useful in Promises when you want to cancel execution without showing any error (eg after user clicks cancel button)
    case general(String)
}

extension AppErr: Equatable {
    static func == (lhs: AppErr, rhs: AppErr) -> Bool {
        switch (lhs, rhs) {
        case (.authentication, .authentication): return true
        case (.connection, .connection): return true
        case (.operation, .operation): return true
        case (.nilSelf, .nilSelf): return true
        case (.value, .value): return true
        case (.unexpected, .unexpected): return true
        case (.cast, .cast): return true
        case (.user, .user): return true
        case (.silentAbort, .silentAbort): return true
        case (.general, .general): return true
        default: return false
        }
    }
}

extension AppErr {
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
