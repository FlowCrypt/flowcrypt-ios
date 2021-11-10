//
//  MessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import FlowCryptCommon
import UIKit

// MARK: - MessageAttachment
struct MessageAttachment: FileType {
    let name: String
    let size: Int
    let data: Data
    var humanReadableSizeString: String {
        return ByteCountFormatter().string(fromByteCount: Int64(self.size))
    }
}

// MARK: - MessageFetchState
enum MessageFetchState {
    case fetch, download(Float), decrypt
}

// MARK: - ProcessedMessage
struct ProcessedMessage {
    enum MessageType {
        case error(MsgBlock.DecryptErr.ErrorType), encrypted, plain
    }

    enum MessageSignature {
        case valid(String), invalid, unknown

        var message: String {
            switch self {
            case .valid(let email):
                return "Signed by \(email)"
            case .invalid:
                return "Bad signature - cannot trust authenticity of this message"
            case .unknown:
                return "Signature not verified - unknown sender public key"
            }
        }

        var icon: String {
            switch self {
            case .valid:
                return "lock"
            case .invalid:
                return "exclamationmark.triangle"
            case .unknown:
                return "xmark"
            }
        }

        var color: UIColor {
            switch self {
            case .valid:
                return .main
            case .invalid:
                return .warningColor
            case .unknown:
                return .errorColor
            }
        }
    }

    let rawMimeData: Data
    let text: String
    let attachments: [MessageAttachment]
    let messageType: MessageType
    let signature: MessageSignature
}

extension ProcessedMessage {
    // TODO: - Ticket - fix with empty state for MessageViewController
    static let empty = ProcessedMessage(
        rawMimeData: Data(),
        text: "loading_title".localized + "...",
        attachments: [],
        messageType: .plain,
        signature: .unknown
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
    private let contactsService: ContactsServiceType
    private let core: Core
    private let logger: Logger

    init(
        messageProvider: MessageProvider = MailProvider.shared.messageProvider,
        keyService: KeyServiceType = KeyService(),
        core: Core = Core.shared,
        passPhraseService: PassPhraseServiceType = PassPhraseService(),
        keyMethods: KeyMethodsType = KeyMethods(),
        contactsService: ContactsServiceType = ContactsService()
    ) {
        self.messageProvider = messageProvider
        self.keyService = keyService
        self.core = core
        self.passPhraseService = passPhraseService
        self.logger = Logger.nested(in: Self.self, with: "MessageService")
        self.keyMethods = keyMethods
        self.contactsService = contactsService
    }

    func checkAndPotentiallySaveEnteredPassPhrase(_ passPhrase: String) async throws -> Bool {
        let keys = try await keyService.getPrvKeyInfo()
        guard keys.isNotEmpty else {
            throw MessageServiceError.emptyKeys
        }
        let keysWithoutPassPhrases = keys.filter { $0.passphrase == nil }
        let matchingKeys = try await keyMethods.filterByPassPhraseMatch(
            keys: keysWithoutPassPhrases,
            passPhrase: passPhrase
        )
        passPhraseService.savePassPhrasesInMemory(passPhrase, for: matchingKeys)
        return matchingKeys.isNotEmpty
    }

    func getAndProcessMessage(
        with input: Message,
        folder: String,
        verificationPubKeys: [String],
        progressHandler: ((MessageFetchState) -> Void)?
    ) async throws -> ProcessedMessage {
        let rawMimeData = try await messageProvider.fetchMsg(
            message: input,
            folder: folder,
            progressHandler: progressHandler
        )
        return try await decryptAndProcessMessage(mime: rawMimeData, verificationPubKeys: verificationPubKeys)
    }

    func decryptAndProcessMessage(mime rawMimeData: Data, verificationPubKeys: [String]) async throws -> ProcessedMessage {
        let keys = try await keyService.getPrvKeyInfo()
        guard keys.isNotEmpty else {
            throw MessageServiceError.emptyKeys
        }
        let decrypted = try await core.parseDecryptMsg(
            encrypted: rawMimeData,
            keys: keys,
            msgPwd: nil,
            isEmail: true,
            verificationPubKeys: verificationPubKeys
        )
        guard !self.hasMsgBlockThatNeedsPassPhrase(decrypted) else {
            throw MessageServiceError.missingPassPhrase(rawMimeData)
        }

        let processedMessage = try await processMessage(rawMimeData: rawMimeData, with: decrypted, keys: keys)

        switch processedMessage.messageType {
        case .error(let errorType):
            switch errorType {
            case .needPassphrase:
                throw MessageServiceError.missingPassPhrase(rawMimeData)
            case .keyMismatch:
                throw MessageServiceError.keyMismatch(rawMimeData)
            default:
                throw MessageServiceError.unknown
            }
        case .plain, .encrypted:
            return processedMessage
        }
    }

    private func processMessage(
        rawMimeData: Data,
        with decrypted: CoreRes.ParseDecryptMsg,
        keys: [PrvKeyInfo]
    ) async throws -> ProcessedMessage {
        let decryptErrBlocks = decrypted.blocks
            .filter { $0.decryptErr != nil }
        let attachments: [MessageAttachment] = try await getAttachments(
            blocks: decrypted.blocks,
            keys: keys
        )
        let messageType: ProcessedMessage.MessageType
        let text: String
        let signature: ProcessedMessage.MessageSignature

        if let decryptErrBlock = decryptErrBlocks.first {
            let rawMsg = decryptErrBlock.content
            let err = decryptErrBlock.decryptErr?.error
            text = "Could not decrypt:\n\(err?.type.rawValue ?? "UNKNOWN"): \(err?.message ?? "??")\n\n\n\(rawMsg)"
            messageType = .error(err?.type ?? .other)
            signature = .unknown
        } else {
            if let longid = decrypted.blocks.first?.verifyRes?.signer,
               let contact = await contactsService.findBy(longId: longid) {
                signature = contact.isValid(longid: longid) ? .valid(contact.email) : .invalid
            } else {
                signature = .unknown
            }
            text = decrypted.text
            messageType = decrypted.replyType == CoreRes.ReplyType.encrypted ? .encrypted : .plain
        }

        return ProcessedMessage(
            rawMimeData: rawMimeData,
            text: text,
            attachments: attachments,
            messageType: messageType,
            signature: signature
        )
    }

    private func getAttachments(
        blocks: [MsgBlock],
        keys: [PrvKeyInfo]
    ) async throws -> [MessageAttachment] {
        let attachmentBlocks = blocks.filter(\.isAttachmentBlock)
        var result: [MessageAttachment] = []
        for block in attachmentBlocks {
            guard let meta = block.attMeta else { continue }

            var name = meta.name
            var data = meta.data
            var size = meta.length
            if block.type == .encryptedAtt { // decrypt
                let decrypted = try await core.decryptFile(encrypted: data, keys: keys, msgPwd: nil)
                data = decrypted.content
                name = decrypted.name
                size = decrypted.content.count
            }

            result.append(MessageAttachment(name: name, size: size, data: data))
        }
        return result
    }

    private func hasMsgBlockThatNeedsPassPhrase(_ msg: CoreRes.ParseDecryptMsg) -> Bool {
        let maybeBlock = msg.blocks.first(where: { $0.decryptErr?.error.type == .needPassphrase })
        guard let block = maybeBlock, let decryptErr = block.decryptErr else {
            return false
        }
        logger.logInfo("missing pass phrase for one of longids \(decryptErr.longids)")
        return true
    }

    private func savePassPhrases(value passPhrase: String, with privateKeys: [PrvKeyInfo]) {
        privateKeys
            .map { PassPhrase(value: passPhrase, fingerprintsOfAssociatedKey: $0.fingerprints) }
            .forEach { self.passPhraseService.savePassPhrase(with: $0, storageMethod: .memory) }
    }
}

private extension MessageAttachment {
    init(block: MsgBlock) {
        self.name = block.attMeta?.name ?? "Attachment"
        self.size = block.attMeta?.length ?? 0
        self.data = block.attMeta?.data ?? Data()
    }
}
