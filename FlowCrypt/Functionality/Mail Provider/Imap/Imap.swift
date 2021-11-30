//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import MailCore

final class Imap: MailServiceProvider {
    let mailServiceProviderType = MailServiceProviderType.imap

    let helper: ImapHelperType
    let messageKindProvider: MessageKindProviderType
    var imapSess: MCOIMAPSession?
    var smtpSess: MCOSMTPSession?

    typealias ImapIndexSet = MCOIndexSet
    typealias ReqKind = MCOIMAPMessagesRequestKind
    typealias Err = MCOErrorCode

    let dataService: ImapSessionProvider & DataServiceType

    lazy var logger = Logger.nested(Self.self)

    private init(
        dataService: ImapSessionProvider & DataServiceType,
        helper: ImapHelperType = ImapHelper(),
        messageKindProvider: MessageKindProviderType = MessageKindProvider()
    ) {
        self.dataService = dataService
        self.helper = helper
        self.messageKindProvider = messageKindProvider
    }
}
