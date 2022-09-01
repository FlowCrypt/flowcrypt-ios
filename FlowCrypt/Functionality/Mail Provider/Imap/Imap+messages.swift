//
//  Imap+messages.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore

extension Imap {
    func fetchMsgsByNumber(
        for folder: String,
        kind: MCOIMAPMessagesRequestKind,
        set: MCOIndexSet
    ) async throws -> [MCOIMAPMessage] {
        return try await execute("fetchMsgsByNumber", { sess, respond in
            sess.fetchMessagesByNumberOperation(
                withFolder: folder,
                requestKind: kind,
                numbers: set
            ).start { error, value, _ in respond(error, value) }
        })
    }

    func fetchMessagesByUIDOperation(
        for folder: String,
        kind: MCOIMAPMessagesRequestKind,
        set: MCOIndexSet
    ) async throws -> [MCOIMAPMessage] {
        return try await execute("fetchMessagesByUIDOperation", { sess, respond in
            sess.fetchMessagesOperation(
                withFolder: folder,
                requestKind: kind,
                uids: set
            ).start { error, value, _ in respond(error, value) }
        })
    }
}
