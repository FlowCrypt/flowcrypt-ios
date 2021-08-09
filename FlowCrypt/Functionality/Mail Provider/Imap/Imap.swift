//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import Promises

final class Imap: MailServiceProvider {
    let mailServiceProviderType = MailServiceProviderType.imap

    typealias Injection = ImapSessionProvider & DataServiceType
    static let shared: Imap = Imap()

    let helper: ImapHelperType
    let messageKindProvider: MessageKindProviderType
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?

    typealias ImapIndexSet = MCOIndexSet
    typealias ReqKind = MCOIMAPMessagesRequestKind
    typealias Err = MCOErrorCode

    var lastErr: [String: AppErr] = [:]
    let dataService: Injection

    lazy var logger = Logger.nested(Self.self)

    private init(
        dataService: Injection = DataService.shared,
        helper: ImapHelperType = ImapHelper(),
        messageKindProvider: MessageKindProviderType = MessageKindProvider()
    ) {
        self.dataService = dataService
        self.helper = helper
        self.messageKindProvider = messageKindProvider
    }
}
