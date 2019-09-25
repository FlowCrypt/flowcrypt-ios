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
            "All you need to know about CryptUP (contains a backup)"
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

    static let unreadMessageFont = UIFont.boldSystemFont(ofSize: 17.0)
    static let readMessageFont = UIFont.systemFont(ofSize: 17.0)
    static let unreadDateFont = UIFont.boldSystemFont(ofSize: 17.0)
    static let readDateFont = UIFont.systemFont(ofSize: 17.0)
    static let unreadMessageTextColor = UIColor.black
    static let readMessageTextColor = UIColor.lightGray
    static let unreadDateTextColor = UIColor(red: 33.0 / 255.0, green: 157.0 / 255.0, blue: 5.0 / 255.0, alpha: 1.0)
    static let readDateTextColor = UIColor.lightGray
    static let green = UIColor(red:0.19, green:0.64, blue:0.09, alpha:1.0)    


    static let rightUiBarButtonItemImageInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: -25)
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

