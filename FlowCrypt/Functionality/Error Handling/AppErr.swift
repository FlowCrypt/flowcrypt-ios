//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum AppErr: Error {
    // network
    case authentication
    case connection
    // code
    case nilSelf // guard let self = self else { throw AppErr.nilSelf }
    case unexpected(String) // we did not expect to ever see this error in practice

    /// something as? Something is unexpectedly nil
    case cast(Any)
    /// user error, useful to throw from Promises
    case user(String)
    /// useful in Promises when you want to cancel execution without showing any error (eg after user clicks cancel button)
    case silentAbort
    case general(String)

    var userMessage: String {
        switch self {
        case .connection: return "error_app_connection".localized
        default: return "" // TODO: - provide description for error if needed
        }
    }
}

extension AppErr: Equatable {
    static func == (lhs: AppErr, rhs: AppErr) -> Bool {
        switch (lhs, rhs) {
        case (.authentication, .authentication): return true
        case (.connection, .connection): return true
        case (.nilSelf, .nilSelf): return true
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
        if let alreadyAppError = error as? AppErr {
            self = alreadyAppError
            return
        }
        let code = (error as NSError).code
        switch code {
        case MCOErrorCode.authentication.rawValue:
            self = .authentication
        case MCOErrorCode.connection.rawValue,
             MCOErrorCode.tlsNotAvailable.rawValue,
             MCOErrorCode.connection.rawValue:
            self = .connection
        default:
            self = .unexpected(error.localizedDescription)
        }
    }
}
