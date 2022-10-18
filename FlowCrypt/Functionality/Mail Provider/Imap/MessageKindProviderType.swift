//
//  MessageKindProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/29/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

protocol MessageKindProviderType {
    var messagesRequestKind: Int { get }
    var imapMessagesRequestKind: MCOIMAPMessagesRequestKind { get }
}

struct MessageKindProvider: MessageKindProviderType {
    var messagesRequestKind: Int {
        MCOIMAPMessagesRequestKind.headers.rawValue
            | MCOIMAPMessagesRequestKind.structure.rawValue
            | MCOIMAPMessagesRequestKind.internalDate.rawValue
            | MCOIMAPMessagesRequestKind.headerSubject.rawValue
            | MCOIMAPMessagesRequestKind.flags.rawValue
            | MCOIMAPMessagesRequestKind.size.rawValue
    }

    var imapMessagesRequestKind: MCOIMAPMessagesRequestKind {
        MCOIMAPMessagesRequestKind(rawValue: messagesRequestKind)
    }
}
