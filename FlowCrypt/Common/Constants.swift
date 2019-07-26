//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct Constants {
    public static let NUMBER_OF_MESSAGES_TO_LOAD = 10
    public static let inboxDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    public static let unreadMessageFont = UIFont.boldSystemFont(ofSize: 17.0)
    public static let readMessageFont = UIFont.systemFont(ofSize: 17.0)
    public static let unreadDateFont = UIFont.boldSystemFont(ofSize: 17.0)
    public static let readDateFont = UIFont.systemFont(ofSize: 17.0)
    public static let unreadMessageTextColor = UIColor.black
    public static let readMessageTextColor = UIColor.lightGray
    public static let unreadDateTextColor = UIColor(red: 33.0 / 255.0, green: 157.0 / 255.0, blue: 5.0 / 255.0, alpha: 1.0)
    public static let readDateTextColor = UIColor.lightGray
    public static let green = UIColor(red:0.19, green:0.64, blue:0.09, alpha:1.0)
}

struct EmailConstant {
    public static let recoverAccountSearchSubject = [
        "Your FlowCrypt Backup",
        "Your CryptUp Backup",
        "Your CryptUP Backup",
        "CryptUP Account Backup",
        "All you need to know about CryptUP (contains a backup)"
    ]
}

struct Language {
    public static let loading = "Loading"
    public static let sending = "Sending"
    public static let enter_recipient = "Enter recipient"
    public static let enter_subject = "Enter subject"
    public static let enter_message = "Enter secure message"
    public static let enter_pass_phrase = "Enter pass phrase"
    public static let encrypted_message_sent = "Encrypted message sent"
    public static let moved_to_trash = "Email moved to Trash"
    public static let email_deleted = "Email deleted"
    public static let email_archived = "Email archived"
    public static let encrypted_reply_sent = "Reply successfully sent"
    public static let could_not_open_message = "Could not open message"
    public static let failed_to_load_messages = "Failed to load messages"
    public static let no_pgp = "Recipient doesn't seem to have encryption set up"
    public static let your_message = "Your message"
    public static let your_reply = "Your reply"
    public static let wrong_pass_phrase_retry = "Wrong pass phrase, please try again"
    public static let no_backups = "No backups found on this account"
    public static let no_internet = "No internet connection"
    public static let use_other_account = "Use other account"
    public static let could_not_configure_google = "Could not configure google services"
    public static let could_not_compose_message = "Could not compose message"
    public static let unhandled_core_err = "Background core service error"
    public static let action_failed = "Action failed"
    public static let could_not_fetch_folders = "Could not fetch folders"
}
