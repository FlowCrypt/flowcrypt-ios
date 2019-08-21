//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum Constants {
    enum Global {
        static let generalError = -1
    }
    // TODO: Anton - Use Themes instead of Constants
    static let NUMBER_OF_MESSAGES_TO_LOAD = 10

    static let inboxDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
  
    static let unreadMessageFont = UIFont.boldSystemFont(ofSize: 17.0)
    static let readMessageFont = UIFont.systemFont(ofSize: 17.0)
    static let unreadDateFont = UIFont.boldSystemFont(ofSize: 17.0)
    static let readDateFont = UIFont.systemFont(ofSize: 17.0)
    static let unreadMessageTextColor = UIColor.black
    static let readMessageTextColor = UIColor.lightGray
    static let unreadDateTextColor = UIColor(red: 33.0 / 255.0, green: 157.0 / 255.0, blue: 5.0 / 255.0, alpha: 1.0)
    static let readDateTextColor = UIColor.lightGray
    static let green = UIColor(red:0.19, green:0.64, blue:0.09, alpha:1.0)    
    static let uiBarButtonItemFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
    static let rightUiBarButtonItemImageInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    
    static let leftUiBarButtonItemImageInsets = UIEdgeInsets(top: 2, left: -25, bottom: 2, right: 0)
    
    static func convertDate(date: Date) -> String {
        let dateFormater = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            dateFormater.dateFormat = "h:mm a"
        }
        else {
            dateFormater.dateFormat = "dd MMM"
        }
        return dateFormater.string(from: date)
    }
}

struct EmailConstant {
    static let recoverAccountSearchSubject = [
        "Your FlowCrypt Backup",
        "Your CryptUp Backup",
        "Your CryptUP Backup",
        "CryptUP Account Backup",
        "All you need to know about CryptUP (contains a backup)"
    ]
}

struct Language {
    static let loading = "Loading"
    static let sending = "Sending"
    static let enter_recipient = "Enter recipient"
    static let enter_subject = "Enter subject"
    static let enter_message = "Enter secure message"
    static let enter_pass_phrase = "Enter pass phrase"
    static let encrypted_message_sent = "Encrypted message sent"
    static let moved_to_trash = "Email moved to Trash"
    static let email_deleted = "Email deleted"
    static let email_archived = "Email archived"
    static let encrypted_reply_sent = "Reply successfully sent"
    static let could_not_open_message = "Could not open message"
    static let failed_to_load_messages = "Failed to load messages"
    static let no_pgp = "Recipient doesn't seem to have encryption set up"
    static let your_message = "Your message"
    static let message_placeholder = "Compose Secure Message"
    static let your_reply = "Your reply"
    static let wrong_pass_phrase_retry = "Wrong pass phrase, please try again"
    static let no_backups = "No backups found on this account"
    static let no_internet = "No internet connection"
    static let use_other_account = "Use other account"
    static let could_not_configure_google = "Could not configure google services"
    static let could_not_compose_message = "Could not compose message"
    static let unhandled_core_err = "Background core service error"
    static let action_failed = "Action failed"
    static let could_not_fetch_folders = "Could not fetch folders"
}
