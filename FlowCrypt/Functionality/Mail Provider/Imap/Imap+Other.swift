//
//  Imap+Other.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore

extension Imap {

    func fetchMessagesIn(
        folder: String,
        uids: MCOIndexSet
    ) async throws -> [MCOIMAPMessage] {
        let kind = self.messageKindProvider.imapMessagesRequestKind
        guard uids.count() > 0 else {
            self.logger.logError("Empty messages fetched")
            return []
        }
        return try await fetchMessage(in: folder, kind: kind, uids: uids)
    }

    func fetchMessage(
        in folder: String,
        kind: MCOIMAPMessagesRequestKind,
        uids: MCOIndexSet
    ) async throws -> [MCOIMAPMessage] {
        return try await execute("fetchMessage", { sess, respond in
            sess.fetchMessagesOperation(
                withFolder: folder,
                requestKind: kind,
                uids: uids
            ).start { error, msgs, _ in respond(error, msgs) }
        })
    }
}
