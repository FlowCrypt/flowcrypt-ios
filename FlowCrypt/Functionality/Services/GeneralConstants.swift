//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum GeneralConstants {
    enum Gmail {
        static let clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        static let redirectURL = URL(string: "com.googleusercontent.apps.679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc:/oauthredirect")!

        // temporary disable search contacts - https://github.com/FlowCrypt/flowcrypt-ios/issues/217
        static let currentScope: [GoogleScope] = [.mail, .userInfo]
    }

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

enum GoogleScope: CaseIterable {
    case userInfo, mail, contacts

    var value: String {
        switch self {
        case .userInfo: return "https://www.googleapis.com/auth/userinfo.profile"
        case .mail: return "https://mail.google.com/"
        case .contacts: return "https://www.googleapis.com/auth/contacts.readonly"
        }
    }
}
