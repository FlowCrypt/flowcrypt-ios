//
//  Imap+messages.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

extension Imap {
    func fetchMsgsByNumber(
        for folder: String,
        kind: MCOIMAPMessagesRequestKind,
        set: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .fetchMessagesByNumberOperation(
                    withFolder: folder,
                    requestKind: kind,
                    numbers: set
                )
                .start { error, messages, _ in // original method sig has 3 args, finalize expects 2 args
                    self.finalize("fetchMsgsByNumber", resolve, reject, retry: {
                        self.fetchMsgsByNumber(for: folder, kind: kind, set: set)
                    })(error, messages as? [MCOIMAPMessage])
                }
        }
    }

    func fetchMessagesByUIDOperation(
        for folder: String,
        kind: MCOIMAPMessagesRequestKind,
        set: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .fetchMessagesByUIDOperation(
                    withFolder: folder,
                    requestKind: kind,
                    uids: set
                )
                .start { error, messages, _ in // original method sig has 3 args, finalize expects 2 args
                    self.finalize("fetchMessagesByUIDOperation", resolve, reject, retry: {
                        self.fetchMessagesByUIDOperation(for: folder, kind: kind, set: set)
                    })(error, messages as? [MCOIMAPMessage])
                }
        }
    }
}
