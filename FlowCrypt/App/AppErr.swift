//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import MailCore
import UIKit

enum AppErr: Error, CustomStringConvertible {
    // network
    case authentication
    case connection
    // code
    case nilSelf // guard let self = self else { throw AppErr.nilSelf }
    case unexpected(String) // we did not expect to ever see this error in practice

    /// something as? Something is unexpectedly nil
    case cast(Any)
    /// user error (user did something wrong?)
    case user(String)
    /// when you want to cancel execution without showing any error (eg after user clicks cancel button)
    case silentAbort
    case noCurrentUser
    case wrongMailProvider
    case general(String)

    var description: String {
        switch self {
        case .connection: return "error_app_connection".localized
        case .wrongMailProvider: return "error_wrong_mail_provider".localized
        case let .general(message), let .user(message), let .unexpected(message):
            return message
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
        case (.noCurrentUser, .noCurrentUser): return true
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
        if let gmailError = error as? GmailServiceError {
            self = .general(gmailError.localizedDescription)
            return
        }
        let code = (error as NSError).code
        switch code {
        case MCOErrorCode.authentication.rawValue:
            self = .authentication
        case MCOErrorCode.connection.rawValue,
             MCOErrorCode.tlsNotAvailable.rawValue:
            self = .connection
        default:
            self = .unexpected(error.localizedDescription)
        }
    }
}

extension UIViewController {
    private func errorToUserFriendlyString(error: Error, title: String) -> String? {
        // todo - more intelligent handling of HttpErr
        do {
            throw error
        } catch let AppErr.user(userErr) {
            // if this is AppErr.user, show only the content of the message to the user, not info about the exception
            return "\(title)\n\n\(userErr)"
        } catch AppErr.silentAbort { // don't show any alert
            return nil
        } catch {
            return "\(title)\n\n\(error)"
        }
    }

    func showAlert(error: Error, message: String, onOk: (() -> Void)? = nil) {
        guard let formatted = errorToUserFriendlyString(error: error, title: message) else {
            hideSpinner()
            onOk?()
            return // silent abort
        }
        showAlert(message: formatted, onOk: onOk)
    }
}
