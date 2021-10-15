//
//  Imap+Other.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore
import Promises

extension Imap {

    func fetchMessagesIn(
        folder: String,
        uids: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let kind = self.messageKindProvider.imapMessagesRequestKind

            guard uids.count() > 0 else {
                self.logger.logError("Empty messages fetched")
                resolve([]) // attempting to fetch an empty set of uids would cause IMAP error
                return
            }

            let messages = try awaitPromise(self.fetchMessage(in: folder, kind: kind, uids: uids))
            resolve(messages)
        }
    }

    func fetchMessage(
        in folder: String,
        kind: MCOIMAPMessagesRequestKind,
        uids: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .fetchMessagesOperation(withFolder: folder, requestKind: kind, uids: uids)?
                .start { error, msgs, _ in
                    guard self.notRetrying("fetchMsgs", error, resolve, reject, retry: {
                        self.fetchMessage(in: folder, kind: kind, uids: uids)
                    }) else { return }

                    guard let messages = msgs else {
                        return reject(AppErr.cast("[MCOIMAPMessage]"))
                    }
                    return resolve(messages)
                }
        }
    }
}
