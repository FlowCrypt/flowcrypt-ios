//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import UIKit

final class Imap {
    static let instance = Imap()

    let inboxFolder = "INBOX"
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?

    typealias ReqKind = MCOIMAPMessagesRequestKind
    typealias Err = MCOErrorCode

    var lastErr: [String: AppErr] = [:]

    let userService: UserService
    let dataManager: DataManager

    var email: String {
        return dataManager.currentUser()?.email ?? ""
    }

    var name: String {
        return dataManager.currentUser()?.name ?? ""
    }

    var token: String {
        return dataManager.currentToken() ?? ""
    }

    private init(userService: UserService = UserService.shared, dataManager: DataManager = .shared) {
        self.userService = userService
        self.dataManager = dataManager

        setup()
    }

    private func setup() {
        guard let token = dataManager.currentToken() else { return }
        getImapSess(newAccessToken: token)
    }
}
