//
//  MessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

// MARK: - MessageAttachment
struct MessageAttachment {
    let name: String
    let size: Int
}

// MARK: - FetchedMessage
struct FetchedMessage {
    enum MessageType {
        case error, encrypted, plain
    }

    let rawMimeData: Data
    let text: String
    let attachments: [MessageAttachment]
    let messageType: MessageType
}

extension FetchedMessage {
    // TODO: - Ticket - fix with empty state for MessageViewController
    static let empty = FetchedMessage(
        rawMimeData: Data(),
        text: "loading_title".localized + "...",
        attachments: [],
        messageType: .plain
    )
}

// MARK: - MessageService
enum MessageServiceError: Error {
    case missedPassPhrase
}

final class MessageService {
    private let messageProvider: MessageProvider
    private let keyService: KeyServiceType
    private let core: Core

    init(
        messageProvider: MessageProvider = MailProvider.shared.messageProvider,
        keyService: KeyServiceType = KeyService(),
        core: Core = Core.shared
    ) {
        self.messageProvider = messageProvider
        self.keyService = keyService
        self.core = core
    }

    func getMessage(with input: Message, folder: String) -> Promise<FetchedMessage> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return }

            let rawMimeData = try awaitPromise(
                self.messageProvider.fetchMsg(message: input, folder: folder)
            )

            guard let keys = try? self.keyService.getPrivateKeys().get() else {
                return reject(MessageServiceError.missedPassPhrase)
            }

            guard keys.isNotEmpty else {
                reject(CoreError.notReady("Could not fetch keys"))
                return
            }

            let decrypted = try self.core.parseDecryptMsg(
                encrypted: rawMimeData,
                keys: keys,
                msgPwd: nil,
                isEmail: true
            )

            let decryptErrBlocks = decrypted.blocks
                .filter { $0.decryptErr != nil }

            let attachments = decrypted.blocks
                .filter(\.isAttachmentBlock)
                .map(MessageAttachment.init)

            let messageType: FetchedMessage.MessageType
            let text: String

            if let decryptErrBlock = decryptErrBlocks.first {
                let rawMsg = decryptErrBlock.content
                let err = decryptErrBlock.decryptErr?.error
                text = "Could not decrypt:\n\(err?.type.rawValue ?? "UNKNOWN"): \(err?.message ?? "??")\n\n\n\(rawMsg)"
                messageType = .error
            } else {
                text = decrypted.text
                messageType = decrypted.replyType == CoreRes.ReplyType.encrypted ? .encrypted : .plain
            }

            let fetchedMessage = FetchedMessage(
                rawMimeData: rawMimeData,
                text: text,
                attachments: attachments,
                messageType: messageType
            )

            resolve(fetchedMessage)
        }
    }
}

private extension MessageAttachment {
    init(block: MsgBlock) {
        self.name = block.attMeta?.name ?? "Attachment"
        self.size = block.attMeta?.length ?? 0
    }
}

private extension MsgBlock {
    var isAttachmentBlock: Bool {
        type == .plainAtt || type == .encryptedAtt || type == .decryptedAtt
    }
}
