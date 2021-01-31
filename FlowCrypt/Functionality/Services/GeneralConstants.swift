//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum GeneralConstants {
    enum Global {
        static let generalError = -1
        static let messageSizeLimit: Int = 5_000_000
    }

    enum EmailConstant {
        static let recoverAccountSearchSubject = [
            "Your FlowCrypt Backup",
            "Your CryptUp Backup",
            "Your CryptUP Backup",
            "CryptUP Account Backup",
            "All you need to know about CryptUP (contains a backup)"
        ]
    }
}

enum MailDestination {
    enum Gmail {
        case trash, inbox

        var path: String {
            switch self {
            case .trash: return "[Gmail]/Trash"
            case .inbox: return "Inbox"
            }
        }
    }
}
