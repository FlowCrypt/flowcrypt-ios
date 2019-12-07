//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import UIKit

final class Imap {
    let inboxFolder = "INBOX"
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?

    typealias ReqKind = MCOIMAPMessagesRequestKind
    typealias Err = MCOErrorCode

    var lastErr: [String: AppErr] = [:]

    let userService: UserServiceType
    let dataManager: DataManagerType

    // TODO: Anton - show login flow instead of fatal error
    var email: String {
        guard let email = dataManager.currentUser?.email else {
            fatalError("Can't use Imap without user data")
        }
        return email
    }

    var name: String {
        guard let name = dataManager.currentUser?.name else {
            fatalError("Can't use Imap without user data")
        }
        return name
    }

    var accessToken: String? {
        guard let token = dataManager.currentToken else {
            fatalError("Can't use Imap without user data")
        }
        return token
    }

    init(userService: UserService = .shared, dataManager: DataManagerType = DataManager.shared) {
        self.userService = userService
        self.dataManager = dataManager

        setup()
    }

    private func setup() {
        guard let token = accessToken else { return }
        getImapSess(newAccessToken: token)
    }
}
