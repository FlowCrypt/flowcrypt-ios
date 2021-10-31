//
//  MessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises
import FlowCryptCommon

// MARK: - MessageAttachment
struct MessageAttachment: FileType {
    let name: String
    let size: Int
    let data: Data
    var humanReadableSizeString: String {
        return ByteCountFormatter().string(fromByteCount: Int64(self.size))
    }
}

// MARK: - ProcessedMessage
struct ProcessedMessage {
    enum MessageType {
        case error(MsgBlock.DecryptErr.ErrorType), encrypted, plain
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
    case missingPassPhrase(_ rawMimeData: Data)
    case wrongPassPhrase(_ rawMimeData: Data, _ passPhrase: String)
    case keyMismatch(_ rawMimeData: Data)
    // Could not fetch keys
    case emptyKeys
    case unknown
}

final class MessageService {
    private enum Constants {
        static let encryptedAttachmentExtension = "pgp"
    }

    private let messageProvider: MessageProvider
    private let keyService: KeyServiceType
    private let keyMethods: KeyMethodsType
    private let passPhraseService: PassPhraseServiceType
    private let core: Core
    private let logger: Logger

    init(
        messageProvider: MessageProvider = MailProvider.shared.messageProvider,
        keyService: KeyServiceType = KeyService(),
        core: Core = Core.shared,
        passPhraseService: PassPhraseServiceType = PassPhraseService(),
        keyMethods: KeyMethodsType = KeyMethods()
    ) {
        self.messageProvider = messageProvider
        self.keyService = keyService
        self.core = core
        self.passPhraseService = passPhraseService
        self.logger = Logger.nested(in: Self.self, with: "MessageService")
        self.keyMethods = keyMethods
    }

    func checkAndPotentiallySaveEnteredPassPhrase(_ passPhrase: String) throws -> Bool {
        guard let keys = try? self.keyService.getPrvKeyInfo().get(), keys.isNotEmpty else {
            throw MessageServiceError.emptyKeys
        }
        let keysWithoutPassPhrases = keys.filter { $0.passphrase == nil }
        let matchingKeys = self.keyMethods.filterByPassPhraseMatch(
            keys: keysWithoutPassPhrases,
            passPhrase: passPhrase
        )
        self.passPhraseService.savePassPhrasesInMemory(passPhrase, for: matchingKeys)
        return matchingKeys.isNotEmpty
    }

    func decryptAndProcessMessage(mime rawMimeData: Data) -> Promise<ProcessedMessage> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return }
            Task<Void, Error> {
                guard let keys = try await self.keyService.getPrvKeyInfo().get(), keys.isNotEmpty else {
                    return reject(CoreError.notReady("Failed to load keys from storage"))
                }
                let decrypted = try await self.core.parseDecryptMsg(
                    encrypted: rawMimeData,
                    keys: keys,
                    msgPwd: nil,
                    isEmail: true
                )
                guard !self.hasMsgBlockThatNeedsPassPhrase(decrypted) else {
                    return reject(MessageServiceError.missingPassPhrase(rawMimeData))
                }

                let processedMessage = try self.processMessage(rawMimeData: rawMimeData, with: decrypted, keys: keys)
                switch processedMessage.messageType {
                case .error(let errorType):
                    switch errorType {
                    case .needPassphrase:
                        reject(MessageServiceError.missingPassPhrase(rawMimeData))
                    case .keyMismatch:
                        reject(MessageServiceError.keyMismatch(rawMimeData))
                    default:
                        reject(MessageServiceError.unknown)
                    }
                case .plain, .encrypted:
                    resolve(processedMessage)
                }
            }
            return
        }
    }

    private func processMessage(rawMimeData: Data, with decrypted: CoreRes.ParseDecryptMsg, keys: [PrvKeyInfo]) throws -> ProcessedMessage {
        let decryptErrBlocks = decrypted.blocks
            .filter { $0.decryptErr != nil }

        let attachments = try decrypted.blocks
            .filter(\.isAttachmentBlock)
            .compactMap { block -> MessageAttachment? in
                guard let attMeta = block.attMeta else { return nil }
                var name = attMeta.name
                let size = attMeta.length
                var data = attMeta.data

                if block.type == .encryptedAtt {
                    data = (try core.decryptFile(encrypted: data, keys: keys, msgPwd: nil).content)
                    name = name.deletingPathExtension
                }

                return MessageAttachment(name: name, size: size, data: data)
            }

        let messageType: ProcessedMessage.MessageType
        let text: String

        if let decryptErrBlock = decryptErrBlocks.first {
            let rawMsg = decryptErrBlock.content
            let err = decryptErrBlock.decryptErr?.error
            text = "Could not decrypt:\n\(err?.type.rawValue ?? "UNKNOWN"): \(err?.message ?? "??")\n\n\n\(rawMsg)"
            messageType = .error(err?.type ?? .other)
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

    private func hasMsgBlockThatNeedsPassPhrase(_ msg: CoreRes.ParseDecryptMsg) -> Bool {
        let maybeBlock = msg.blocks.first(where: { $0.decryptErr?.error.type == .needPassphrase })
        guard let block = maybeBlock, let decryptErr = block.decryptErr else {
            return false
        }
        logger.logInfo("missing pass phrase for one of longids \(decryptErr.longids)")
        return true
    }
}

private extension MessageAttachment {
    init(block: MsgBlock) {
        self.name = block.attMeta?.name ?? "Attachment"
        self.size = block.attMeta?.length ?? 0
        self.data = block.attMeta?.data ?? Data()
    }
}
