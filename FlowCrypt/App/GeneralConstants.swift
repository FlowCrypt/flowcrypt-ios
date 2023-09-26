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
        static let trashLabelPath = "TRASH"
        // Empty pass is For All MAIL
        static let standardGmailPaths = ["INBOX", "CHAT", "SENT", "IMPORTANT", trashLabelPath, "DRAFT", "SPAM", "STARRED", "UNREAD", ""]
        static let gmailRecoveryEmailSubjects = [
            "Your FlowCrypt Backup",
            "Your CryptUp Backup",
            "All you need to know about CryptUP (contains a backup)",
            "CryptUP Account Backup"
        ]
    }

    enum Global {
        static let attachmentSizeLimit = 10_000_000
        static let signatureSeparator = "______"
    }

    enum Mock {
        static let backendUrl = "https://127.0.0.1:8001"
        static let userEmail = "e2e.enterprise.test@flowcrypt.com"
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
