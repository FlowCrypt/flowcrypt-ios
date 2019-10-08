//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum Constants {
    enum Global {
        static let generalError = -1
        static let gmailRootPath = "[Gmail]"
        static let gmailAllMailPath = "[Gmail]/All Mail"
    }

    enum EmailConstant {
        static let recoverAccountSearchSubject = [
            "Your FlowCrypt Backup",
            "Your CryptUp Backup",
            "Your CryptUP Backup",
            "CryptUP Account Backup",
            "All you need to know about CryptUP (contains a backup)",
        ]
    }

    // TODO: update texts on failed archive/delete operation.
    enum ErrorTexts {
        enum Message {
            static let moveToTrash = "Unable to move message to Trash"
            static let archive = "Unable to archive message"
            static let permanentlyDelete = "Unable to delete message"
        }
    }
}

struct Language {
    static let loading = "Loading"
    static let moved_to_trash = "Email moved to Trash"
    static let email_deleted = "Email deleted"
    static let email_archived = "Email archived"
    static let could_not_open_message = "Could not open message"
    static let failedToLoadMessages = "Failed to load messages"
    static let your_message = "Your message"
    static let message_placeholder = "Compose Secure Message"
    static let your_reply = "Your reply"
    static let no_internet = "No internet connection"
    static let could_not_configure_google = "Could not configure google services"
    static let unhandled_core_err = "Background core service error"
    static let could_not_fetch_folders = "Could not fetch folders"
}
