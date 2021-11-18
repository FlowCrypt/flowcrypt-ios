//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum GeneralConstants {
    enum Gmail {
        static let clientID = "679326713487-5r16ir2f57bpmuh2d6dal1bcm9m1ffqc.apps.googleusercontent.com"
        static let redirectURL = URL(string: "com.googleusercontent.apps.679326713487-5r16ir2f57bpmuh2d6dal1bcm9m1ffqc:/oauthredirect")!
        static let mailScope: [GoogleScope] = [.userInfo, .userEmail, .mail]
        static let contactsScope: [GoogleScope] = mailScope + [.contacts, .otherContacts]
    }

    enum Global {
        static let generalError = -1
        static let attachmentSizeLimit: Int = 10_000_000
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
    case userInfo, userEmail, mail, contacts, otherContacts

    var value: String {
        switch self {
        case .userInfo: return "https://www.googleapis.com/auth/userinfo.profile"
        case .userEmail: return "https://www.googleapis.com/auth/userinfo.email"
        case .mail: return "https://mail.google.com/"
        case .contacts: return "https://www.googleapis.com/auth/contacts"
        case .otherContacts: return "https://www.googleapis.com/auth/contacts.other.readonly"
        }
    }
}
