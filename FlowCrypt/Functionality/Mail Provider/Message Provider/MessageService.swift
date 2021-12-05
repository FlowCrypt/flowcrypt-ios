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

// MARK: - MessageFetchState
enum MessageFetchState {
    case fetch, download(Float), decrypt
}

// MARK: - ProcessedMessage
struct ProcessedMessage {
    enum MessageType: Hashable {
        case error(MsgBlock.DecryptErr.ErrorType), encrypted, plain
    }

    enum MessageSignature: Hashable {
        case good, goodMixed, unsigned, error(String), missingPubkey(String), partial, bad, pending

        var message: String {
            switch self {
            case .good:
                return "message_signed".localized
            case .goodMixed:
                return "message_signature_good_mixed".localized
            case .unsigned:
                return "message_not_signed".localized
            case .error(let message):
                return "message_signature_verify_error".localizeWithArguments(message)
            case .missingPubkey(let longid):
                let message = "message_missing_pubkey".localizeWithArguments(longid)
                return "message_signature_verify_error".localizeWithArguments(message)
            case .partial:
                return "message_signature_partial".localized
            case .bad:
                return "message_bad_signature".localized
            case .pending:
                return "message_signature_pending".localized
            }
        }

        var icon: String {
            switch self {
            case .good, .goodMixed:
                return "lock"
            case .error, .missingPubkey, .partial:
                return "exclamationmark.triangle"
            case .unsigned, .bad:
                return "xmark"
            case .pending:
                return "clock"
            }
        }

        var color: UIColor {
            switch self {
            case .good, .goodMixed:
                return .main
            case .error, .missingPubkey, .partial:
                return .warningColor
            case .unsigned, .bad:
                return .errorColor
            case .pending:
                return .lightGray
            }
        }
    }

    let rawMimeData: Data
    let text: String
    let attachments: [MessageAttachment]
    let messageType: MessageType
    var signature: MessageSignature?
}

extension ProcessedMessage {
    // TODO: - Ticket - fix with empty state for ThreadDetailsViewController
    static let empty = ProcessedMessage(
        rawMimeData: Data(),
        text: "loading_title".localized + "...",
        attachments: [],
        messageType: .plain,
        signature: .unsigned
    )
}

// MARK: - MessageService
enum MessageServiceError: Error {
    case missingPassPhrase(_ rawMimeData: Data)
    case wrongPassPhrase(_ rawMimeData: Data, _ passPhrase: String)
    // Could not fetch keys
    case emptyKeys
    case unknown
}

final class MessageService {

    private let messageProvider: MessageProvider
    private let keyMethods: KeyMethodsType
    private let contactsService: ContactsServiceType
    private let core: Core
    private let logger: Logger
    private let keyService: KeyServiceType
    private let passPhraseService: PassPhraseServiceType

    init(
        core: Core = Core.shared,
        keyMethods: KeyMethodsType = KeyMethods(),
        contactsService: ContactsServiceType,
        keyService: KeyServiceType,
        messageProvider: MessageProvider,
        passPhraseService: PassPhraseServiceType
    ) {
        self.keyService = keyService
        self.passPhraseService = passPhraseService
        self.messageProvider = messageProvider
        self.core = core
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
        try passPhraseService.savePassPhrasesInMemory(passPhrase, for: matchingKeys)
        return matchingKeys.isNotEmpty
    }

    func getAndProcessMessage(
        with input: Message,
        folder: String,
        onlyLocalKeys: Bool,
        progressHandler: ((MessageFetchState) -> Void)?
    ) async throws -> ProcessedMessage {
        let rawMimeData = try await messageProvider.fetchMsg(
            message: input,
            folder: folder,
            progressHandler: progressHandler
        )
        return try await decryptAndProcessMessage(mime: rawMimeData,
                                                  sender: input.sender,
                                                  onlyLocalKeys: onlyLocalKeys)
    }

    func decryptAndProcessMessage(mime rawMimeData: Data,
                                  sender: String?,
                                  onlyLocalKeys: Bool) async throws -> ProcessedMessage {
        let keys = try await keyService.getPrvKeyInfo()
        guard keys.isNotEmpty else {
            throw MessageServiceError.emptyKeys
        }
        let verificationPubKeys = try await fetchVerificationPubKeys(for: sender, onlyLocal: onlyLocalKeys)
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

        return try await processMessage(rawMimeData: rawMimeData,
                                        sender: sender,
                                        with: decrypted,
                                        keys: keys)
    }

    private func processMessage(
        rawMimeData: Data,
        sender: String?,
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
        let signature: ProcessedMessage.MessageSignature?

        if let decryptErrBlock = decryptErrBlocks.first {
            let rawMsg = decryptErrBlock.content
            let err = decryptErrBlock.decryptErr?.error
            text = "Could not decrypt:\n\(err?.type.rawValue ?? "UNKNOWN"): \(err?.message ?? "??")\n\n\n\(rawMsg)"
            messageType = .error(err?.type ?? .other)
            signature = nil
        } else {
            text = decrypted.text
            messageType = decrypted.replyType == CoreRes.ReplyType.encrypted ? .encrypted : .plain
            signature = await evaluateSignatureVerificationResult(
                signature: decrypted.blocks.first?.verifyRes
            )
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

        var attachments: [MessageAttachment] = []
        for block in attachmentBlocks {
            guard let meta = block.attMeta else { continue }

            let attachment: MessageAttachment
            if block.type == .encryptedAtt { // decrypt
                let decrypted = try await core.decryptFile(encrypted: meta.data, keys: keys, msgPwd: nil)
                attachment = MessageAttachment(name: decrypted.name,
                                               data: decrypted.content)
            } else {
                attachment = MessageAttachment(name: meta.name,
                                               data: meta.data)
            }

            attachments.append(attachment)
        }

        return attachments
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

// MARK: - Message verification
extension MessageService {
    private func fetchVerificationPubKeys(for sender: String?, onlyLocal: Bool) async throws -> [String] {
        guard let sender = sender else { return [] }

        let pubKeys = contactsService.retrievePubKeys(for: sender)
        if pubKeys.isNotEmpty || onlyLocal { return pubKeys }

        guard let contact = try? await contactsService.searchContact(with: sender)
        else { return [] }

        return contact.pubKeys.map(\.armored)
    }

    private func evaluateSignatureVerificationResult(
        signature: MsgBlock.VerifyRes?
    ) async -> ProcessedMessage.MessageSignature {
        guard let signature = signature else { return .unsigned }

        if let error = signature.error { return .error(error) }

        guard let signer = signature.signer else { return .unsigned }

        guard signature.match != nil else { return .missingPubkey(signer) }

        guard signature.match == true else { return .bad }

        guard signature.partial != true else { return .partial }

        guard signature.mixed != true else { return .goodMixed }

        return .good
    }
}

private extension MessageAttachment {
    init(block: MsgBlock) {
        self.name = block.attMeta?.name ?? "Attachment"
        self.data = block.attMeta?.data ?? Data()
    }
}
