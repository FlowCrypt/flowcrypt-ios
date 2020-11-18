//
//  Imap+MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap: MessagesListProvider {
    func fetchMessages(for folder: String, count: Int, using pagination: MessagesListPagination) -> Promise<MessageContext> {
        guard case let .byNumber(from) = pagination else {
            fatalError("Pagination \(pagination) is not supported for this provider")
        }
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let folderInfo = try await(self.folderInfo(for: folder))
            let totalCount = Int(folderInfo.messageCount)
            if totalCount == 0  {
                resolve(MessageContext(messages: [], pagination: .byNumber(total: totalCount)))
            }
            let set = self.helper.createSet(
                for: count,
                total: totalCount,
                from: from ?? 0
            )
            let kind = self.messageKindProvider.imapMessagesRequestKind
            let messages = try await(self.fetchMsgsByNumber(for: folder, kind: kind, set: set))
            resolve(MessageContext(messages: messages, pagination: .byNumber(total: totalCount)))
        }
    }

    private func folderInfo(for path: String) -> Promise<MCOIMAPFolderInfo> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .folderInfoOperation(path)
                .start(self.finalize("folderInfo", resolve, reject, retry: {
                    self.folderInfo(for: path)
                }))
        }
    }
}
