//
//  Imap+MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore
import Promises

extension Imap: MessagesListProvider {
    func fetchMessages(using context: FetchMessageContext) -> Promise<MessageContext> {
        guard case let .byNumber(from) = context.pagination else {
            fatalError("Pagination \(String(describing: context.pagination)) is not supported for this provider")
        }
        guard let folderPath = context.folderPath else {
            fatalError("Folder path should not be nil for IMAP")
        }

        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            let folderInfo = try awaitPromise(self.folderInfo(for: folderPath))
            let totalCount = Int(folderInfo.messageCount)
            if totalCount == 0 {
                resolve(MessageContext(messages: [], pagination: .byNumber(total: totalCount)))
            }
            let set = self.helper.createSet(
                for: context.count ?? 10,
                total: totalCount,
                from: from ?? 0
            )
            let kind = self.messageKindProvider.imapMessagesRequestKind
            let messages = try awaitPromise(self.fetchMsgsByNumber(for: folderPath, kind: kind, set: set))
                .map(Message.init)

            resolve(MessageContext(messages: messages, pagination: .byNumber(total: totalCount)))
        }
    }

    private func folderInfo(for path: String) -> Promise<MCOIMAPFolderInfo> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }

            self.imapSess?
                .folderInfoOperation(path)
                .start(self.finalize("folderInfo", resolve, reject, retry: {
                    self.folderInfo(for: path)
                }))
        }
    }
}

// MARK: - Message
extension Message {
    init(imapMessage: MCOIMAPMessage) {
        // swiftlint:disable compiler_protocol_init
        let labels = Array(arrayLiteral: imapMessage.flags).map(MessageLabelType.init).map(MessageLabel.init)
        self.init(
            identifier: Identifier(intId: Int(imapMessage.uid)),
            date: imapMessage.header.date,
            sender: imapMessage.header.from.mailbox ?? imapMessage.header.sender.mailbox,
            subject: imapMessage.header.subject,
            size: Int(imapMessage.size),
            labels: labels,
            attachmentIds: []
        )
    }
}
