//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import UIKit

final class Imap {
    static let shared: Imap = Imap()
    
    let helper: ImapHelperType
    let messageKindProvider: MessageKindProviderType
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?
    
    typealias ImapIndexSet = MCOIndexSet
    typealias ReqKind = MCOIMAPMessagesRequestKind
    typealias Err = MCOErrorCode

    var lastErr: [String: AppErr] = [:]

    let userService: UserServiceType
    let dataService: DataServiceType

    // TODO: Anton - show login flow instead of fatal error
    var email: String {
        guard let email = dataService.currentUser?.email else {
            fatalError("Can't use Imap without user data")
        }
        return email
    }

    var name: String {
        guard let name = dataService.currentUser?.name else {
            fatalError("Can't use Imap without user data")
        }
        return name
    }

    var accessToken: String? {
        guard let token = dataService.currentToken else {
            fatalError("Can't use Imap without user data")
        }
        return token
    }

    private init(
        userService: UserService = .shared,
        dataService: DataServiceType = DataService.shared,
        helper: ImapHelperType = ImapHelper(),
        messageKindProvider: MessageKindProviderType = MessageKindProvider()
    ) {
        self.userService = userService
        self.dataService = dataService
        self.helper = helper
        self.messageKindProvider = messageKindProvider
    }

    func setup() {
        guard let token = accessToken else { return }
        getImapSess(newAccessToken: token)
        getSmtpSess(newAccessToken: token)
    }
}
