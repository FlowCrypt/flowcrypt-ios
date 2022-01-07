//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import MailCore

final class Imap: MailServiceProvider {

    let mailServiceProviderType = MailServiceProviderType.imap

    let user: User
    let helper: ImapHelperType
    let messageKindProvider: MessageKindProviderType
    var imapSess: MCOIMAPSession? {
        imapSessionProvider.imapSession()
            .map(MCOIMAPSession.init)
    }
    var smtpSess: MCOSMTPSession? {
        imapSessionProvider.smtpSession()
            .map(MCOSMTPSession.init)
    }

    typealias ImapIndexSet = MCOIndexSet
    typealias ReqKind = MCOIMAPMessagesRequestKind
    typealias Err = MCOErrorCode

    let imapSessionProvider: ImapSessionProviderType

    lazy var logger = Logger.nested(Self.self)

    init(
        user: User,
        helper: ImapHelperType = ImapHelper(),
        messageKindProvider: MessageKindProviderType = MessageKindProvider()
    ) {
        self.user = user
        self.imapSessionProvider = ImapSessionProvider(user: user)
        self.helper = helper
        self.messageKindProvider = messageKindProvider
    }
}
