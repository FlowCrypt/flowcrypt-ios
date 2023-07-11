//
//  Imap+MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

extension Imap: MessagesListApiClient {
    func fetchMessages(using context: FetchMessageContext) async throws -> MessageContext {
        guard case let .byNumber(from) = context.pagination else {
            throw GmailApiError.paginationError(context.pagination)
        }
        guard let folderPath = context.folderPath else {
            throw ImapError.folderRequired
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
        return try await execute("folderInfo") { sess, respond in
            sess.folderInfoOperation(
                path
            ).start { error, info in respond(error, info) }
        }
    }
}

// MARK: - Message
extension Message {
    init(imapMessage: MCOIMAPMessage) {
        // swiftlint:disable compiler_protocol_init
        let labels = Array(arrayLiteral: imapMessage.flags).map(MessageLabel.init)
        // swiftlint:enable compiler_protocol_init
        var sender: Recipient?
        if let senderAddress = imapMessage.header.from ?? imapMessage.header.sender,
           senderAddress.mailbox != nil,
           let encodedString = senderAddress.nonEncodedRFC822String() {
            sender = Recipient(encodedString)
        }

        self.init(
            identifier: Identifier(intId: Int(imapMessage.uid)),
            date: imapMessage.header.date,
            sender: sender,
            subject: imapMessage.header.subject,
            size: Int(imapMessage.size),
            labels: labels,
            attachmentIds: [],
            body: MessageBody(text: "", html: nil, attachment: nil) // TODO: implement body parsing
        )
    }
}
