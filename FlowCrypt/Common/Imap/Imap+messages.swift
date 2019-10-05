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

struct MessageContext {
    let messages: [MCOIMAPMessage]
    let totalMessages: Int
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
                .start { error, folders in
                    guard self.notRetrying("folderInfo", error, resolve, reject, retry: { self.folderInfo(for: path) }) else { return }
                    if let error = error {
                        reject(AppErr(error))
                    } else if let folders = folders {
                        resolve(folders)
                    } else {
                        reject(AppErr.cast("value as? [MCOIMAPFolder] failed"))
                    }
                }
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
            self.getImapSess()
                .fetchMessagesByNumberOperation(withFolder: folder, requestKind: kind, numbers: set)
                .start { error, messages, _ in
                    guard self.notRetrying("fetchMsgsByNumber", error, resolve, reject, retry: { self.fetchMsgsByNumber(for: folder, kind: kind, set: set) }) else { return }
                    if let error = error {
                        reject(AppErr(error))
                    } else if let messages = messages as? [MCOIMAPMessage] {
                        resolve(messages)
                    } else {
                        reject(AppErr.cast("messages as? [MCOIMAPMessage]"))
                    }
                }
        }
    }
}
