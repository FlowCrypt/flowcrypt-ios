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
    var imapSess: MCOIMAPSession {
        get throws {
            let imapSeesion = try imapSessionProvider.imapSession()
            return MCOIMAPSession(session: imapSeesion)
        }
    }

    var smtpSess: MCOSMTPSession {
        get throws {
            let smtpSession = try imapSessionProvider.smtpSession()
            return MCOSMTPSession(session: smtpSession)
        }
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
