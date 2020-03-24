//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum GeneralConstants {
    enum Global {
        static let generalError = -1
        static let gmailRootPath = "[Gmail]"
        static let gmailAllMailPath = "[Gmail]/All Mail"
        static let messageSizeLimit: Int = 5_000_000
    }

    enum EmailConstant {
        static let recoverAccountSearchSubject = [
            "1Your FlowCrypt Backup",
            "1Your CryptUp Backup",
            "1Your CryptUP Backup",
            "1CryptUP Account Backup",
            "1All you need to know about CryptUP (contains a backup)",
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
