//
//  MessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

// MARK: - MessageAttachment
struct MessageAttachment: FileType {
    let name: String
    let size: Int
    let data: Data
}

// MARK: - ProcessedMessage
struct ProcessedMessage {
    enum MessageType {
        case error, encrypted, plain
    }

    let rawMimeData: Data
    let text: String
    let attachments: [MessageAttachment]
    let messageType: MessageType
}

extension ProcessedMessage {
    // TODO: - Ticket - fix with empty state for MessageViewController
    static let empty = ProcessedMessage(
        rawMimeData: Data(),
        text: "loading_title".localized + "...",
        attachments: [],
        messageType: .plain
    )
}

// MARK: - MessageService
enum MessageServiceError: Error {
    case missedPassPhrase(_ rawMimeData: Data)
    case wrongPassPhrase(_ rawMimeData: Data, _ passPhrase: String)
    // Could not fetch keys
    case emptyKeys
}

final class MessageService {
    private let messageProvider: MessageProvider
    private let keyService: KeyServiceType
    private let passPhraseService: PassPhraseServiceType
    private let core: Core

    init(
        messageProvider: MessageProvider = MailProvider.shared.messageProvider,
        keyService: KeyServiceType = KeyService(),
        core: Core = Core.shared,
        passPhraseService: PassPhraseServiceType = PassPhraseService()
    ) {
        self.messageProvider = messageProvider
        self.keyService = keyService
        self.core = core
        self.passPhraseService = passPhraseService
    }

    func validateMessage(rawMimeData: Data, with passPhrase: String) -> Promise<ProcessedMessage> {
        Promise<ProcessedMessage> { [weak self] resolve, reject in
            guard let self = self else { return }

            guard let keys = try? self.keyService.getPrvKeyInfo(with: passPhrase).get(), keys.isNotEmpty else {
                return reject(MessageServiceError.emptyKeys)
            }

            let decrypted = try self.core.parseDecryptMsg(
                encrypted: rawMimeData,
                keys: keys,
                msgPwd: nil,
                isEmail: true
            )

            let isWrongPassPhraseError = decrypted.blocks.first(where: { block -> Bool in
                guard let errorBlock = block.decryptErr, case .needPassphrase = errorBlock.error.type else {
                    return false
                }
                return true
            })

            if isWrongPassPhraseError != nil {
                reject(MessageServiceError.wrongPassPhrase(rawMimeData, passPhrase))
            } else {
                self.savePassPhrases(value: passPhrase, with: keys)
                let processedMessage = self.processMessage(rawMimeData: rawMimeData, with: decrypted)
                resolve(processedMessage)
            }
        }
    }

    private func savePassPhrases(value passPhrase: String, with privateKeys: [PrvKeyInfo]) {
        privateKeys
            .map { PassPhrase(value: passPhrase, fingerprints: $0.fingerprints) }
            .forEach { self.passPhraseService.savePassPhrase(with: $0, inStorage: false) }
    }

    func getAndProcessMessage(with input: Message, folder: String) -> Promise<ProcessedMessage> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return }

            let rawMimeData = try awaitPromise(
                self.messageProvider.fetchMsg(message: input, folder: folder)
            )

            guard let keys = try? self.keyService.getPrvKeyInfo(with: nil).get() else {
                return reject(MessageServiceError.missedPassPhrase(rawMimeData))
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

            let processedMessage = self.processMessage(rawMimeData: rawMimeData, with: decrypted)
            resolve(processedMessage)
        }
    }

    private func processMessage(rawMimeData: Data, with decrypted: CoreRes.ParseDecryptMsg) -> ProcessedMessage {
        let decryptErrBlocks = decrypted.blocks
            .filter { $0.decryptErr != nil }

        let attachments = decrypted.blocks
            .filter(\.isAttachmentBlock)
            .map(MessageAttachment.init)

        let messageType: ProcessedMessage.MessageType
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

        return ProcessedMessage(
            rawMimeData: rawMimeData,
            text: text,
            attachments: attachments,
            messageType: messageType
        )
    }
}

private extension MessageAttachment {
    init(block: MsgBlock) {
        self.name = block.attMeta?.name ?? "Attachment"
        self.size = block.attMeta?.length ?? 0
        self.data = block.attMeta?.data ?? Data()
    }
}
