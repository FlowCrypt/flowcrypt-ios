//
//  MessageKindProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/29/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol MessageKindProvider {
    var messagesRequestKind: Int { get }
    var imapMessagesRequestKind: MCOIMAPMessagesRequestKind { get }
}

struct DefaultMessageKindProvider: MessageKindProvider {
    var messagesRequestKind: Int {
        return MCOIMAPMessagesRequestKind.headers.rawValue
            | MCOIMAPMessagesRequestKind.structure.rawValue
            | MCOIMAPMessagesRequestKind.internalDate.rawValue
            | MCOIMAPMessagesRequestKind.headerSubject.rawValue
            | MCOIMAPMessagesRequestKind.flags.rawValue
            | MCOIMAPMessagesRequestKind.size.rawValue
    }

    var imapMessagesRequestKind: MCOIMAPMessagesRequestKind {
        return MCOIMAPMessagesRequestKind(rawValue: messagesRequestKind)
    }
}
