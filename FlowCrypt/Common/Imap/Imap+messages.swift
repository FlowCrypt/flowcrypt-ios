//
//  Imap+messages.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol MessageProvider {
    func fetchMessages(for folder: String, count: Int, from: Int?) -> Promise<MessageContext>
}

extension Imap: MessageProvider {
    func fetchMessages(for folder: String, count: Int, from: Int?) -> Promise<MessageContext> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
            let folderInfo = try await(self.folderInfo(for: folder))
            let totalCount = Int(folderInfo.messageCount)
            let set = self.createSet(for: count, total: totalCount, from: from ?? 0)
            let kind = DefaultMessageKindProvider().imapMessagesRequestKind
            let messages = try await(self.fetchMsgsByNumber(for: folder, kind: kind, set: set))
            resolve(MessageContext(messages: messages, totalMessages: totalCount))
        }
    }

    private func folderInfo(for path: String) -> Promise<MCOIMAPFolderInfo> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
            self.getImapSess()
                .folderInfoOperation(path)
                .start(self.finalize("folderInfo", resolve, reject, retry: {
                    self.folderInfo(for: path)
                }))
        }
    }

    private func createSet(
        for numberOfMessages: Int,
        total: Int,
        from: Int
    ) -> MCOIndexSet {
        var length = numberOfMessages - 1
        if length < 0 {
            length = 0
        }
        var diff = total - length - from
        if diff < 0 {
            diff = 1
        }
        let range = MCORange(location: UInt64(diff), length: UInt64(length))
        return MCOIndexSet(range: range)
    }

    private func fetchMsgsByNumber(
        for folder: String,
        kind: MCOIMAPMessagesRequestKind,
        set: MCOIndexSet
    ) -> Promise<[MCOIMAPMessage]> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
            let start = DispatchTime.now() // because we only call finalize once it's finished, we need to supply start time
            self.getImapSess()
                .fetchMessagesByNumberOperation(withFolder: folder, requestKind: kind, numbers: set)
                .start { error, messages, _ in // original method sig has 3 args, finalize expects 2 args
                    self.finalize("fetchMsgsByNumber", resolve, reject, retry: {
                        self.fetchMsgsByNumber(for: folder, kind: kind, set: set)
                    }, start: start)(error, messages as? [MCOIMAPMessage])
                }
        }
    }
}
