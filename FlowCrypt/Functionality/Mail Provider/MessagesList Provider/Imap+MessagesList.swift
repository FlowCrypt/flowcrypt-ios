//
//  Imap+MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore

extension Imap: MessagesListProvider {
    func fetchMessages(using context: FetchMessageContext) async throws -> MessageContext {
        guard case let .byNumber(from) = context.pagination else {
            fatalError("Pagination \(String(describing: context.pagination)) is not supported for this provider")
        }
        guard let folderPath = context.folderPath else {
            fatalError("Folder path should not be nil for IMAP")
        }

        let folderInfo = try await folderInfo(for: folderPath)
        let totalCount = Int(folderInfo.messageCount)
        if totalCount == 0 {
            return MessageContext(messages: [], pagination: .byNumber(total: totalCount))
        }
        let set = helper.createSet(
            for: context.count ?? 10,
            total: totalCount,
            from: from ?? 0
        )
        let kind = messageKindProvider.imapMessagesRequestKind
        let messages = try await fetchMsgsByNumber(for: folderPath, kind: kind, set: set)
            .map(Message.init)

        return MessageContext(messages: messages, pagination: .byNumber(total: totalCount))
    }

    private func folderInfo(for path: String) async throws -> MCOIMAPFolderInfo {
        return try await execute("folderInfo", { sess, respond in
            sess.folderInfoOperation(
                path
            ).start { error, info in respond(error, info) }
        })
    }
}

// MARK: - Message
extension Message {
    init(imapMessage: MCOIMAPMessage) {
        // swiftlint:disable compiler_protocol_init
        let labels = Array(arrayLiteral: imapMessage.flags).map(MessageLabelType.init).map(MessageLabel.init)
        var sender: MessageRecipient?
        if let senderString = imapMessage.header.from ?? imapMessage.header.sender {
            sender = MessageRecipient(senderString.nonEncodedRFC822String())
        }

        self.init(
            identifier: Identifier(intId: Int(imapMessage.uid)),
            date: imapMessage.header.date,
            sender: sender,
            subject: imapMessage.header.subject,
            size: Int(imapMessage.size),
            labels: labels,
            attachmentIds: []
        )
    }
}
