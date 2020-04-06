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
    let sessionProvider: SessionCredentialsProvider

    private init(
        userService: UserService = .shared,
        dataService: DataServiceType = DataService.shared,
        helper: ImapHelperType = ImapHelper(),
        messageKindProvider: MessageKindProviderType = MessageKindProvider(),
        sessionProvider: SessionCredentialsProvider = ImapSessionService()
    ) {
        self.userService = userService
        self.dataService = dataService
        self.helper = helper
        self.messageKindProvider = messageKindProvider
        self.sessionProvider = sessionProvider
    }
}
