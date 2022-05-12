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

// MARK: - MessageServiceError
enum MessageServiceError: Error, CustomStringConvertible {
    case missingPassPhrase(_ rawMimeData: Data)
    case wrongPassPhrase(_ rawMimeData: Data, _ passPhrase: String)
    case emptyKeys
    case attachmentNotFound
    case attachmentDecryptFailed(_ message: String)
}

extension MessageServiceError {
    var description: String {
        switch self {
        case .missingPassPhrase:
            return "Passphrase is missing"
        case .wrongPassPhrase:
            return "Passphrase is wrong"
        case .emptyKeys:
            return "Could not fetch keys"
        case .attachmentNotFound:
            return "Failed to download attachment"
        case .attachmentDecryptFailed(let message):
            return message
        }
    }
}

// MARK: - MessageService
final class MessageService {

    private let messageProvider: MessageProvider
    private let keyMethods: KeyMethodsType
    private let localContactsProvider: LocalContactsProviderType
    private let core: Core
    private let logger: Logger
    private let keyAndPassPhraseStorage: KeyAndPassPhraseStorageType
    private let passPhraseService: PassPhraseServiceType
    private let pubLookup: PubLookupType

    init(
        core: Core = Core.shared,
        keyMethods: KeyMethodsType = KeyMethods(),
        localContactsProvider: LocalContactsProviderType,
        pubLookup: PubLookupType,
        keyAndPassPhraseStorage: KeyAndPassPhraseStorageType,
        messageProvider: MessageProvider,
        passPhraseService: PassPhraseServiceType
    ) {
        self.keyAndPassPhraseStorage = keyAndPassPhraseStorage
        self.passPhraseService = passPhraseService
        self.messageProvider = messageProvider
        self.core = core
        self.logger = Logger.nested(in: Self.self, with: "MessageService")
        self.keyMethods = keyMethods
        self.localContactsProvider = localContactsProvider
        self.pubLookup = pubLookup
    }

    func checkAndPotentiallySaveEnteredPassPhrase(_ passPhrase: String, userEmail: String) async throws -> Bool {
        let keys = try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: userEmail)
        guard keys.isNotEmpty else {
            throw MessageServiceError.emptyKeys
        }
        let keysWithoutPassPhrases = keys.filter { $0.passphrase == nil }
        let matchingKeys = try await keyMethods.filterByPassPhraseMatch(
            keys: keysWithoutPassPhrases,
            passPhrase: passPhrase
        )
        try passPhraseService.savePassPhrasesInMemory(for: userEmail, passPhrase, privateKeys: matchingKeys)
        return matchingKeys.isNotEmpty
    }

    func getAndProcessMessage(
        with input: Message,
        folder: String,
        onlyLocalKeys: Bool,
        userEmail: String,
        progressHandler: ((MessageFetchState) -> Void)?
    ) async throws -> ProcessedMessage {
        let rawMimeData = try await messageProvider.fetchMsg(
            message: input,
            folder: folder,
            progressHandler: progressHandler
        )
        return try await decryptAndProcessMessage(
            mime: rawMimeData,
            sender: input.sender,
            onlyLocalKeys: onlyLocalKeys,
            userEmail: userEmail
        )
    }

    func decryptAndProcessMessage(
        mime rawMimeData: Data,
        sender: Recipient?,
        onlyLocalKeys: Bool,
        userEmail: String
    ) async throws -> ProcessedMessage {
        let keys = try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: userEmail)
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

        return try await processMessage(
            rawMimeData: rawMimeData,
            with: decrypted
        )
    }

    func decrypt(attachment: MessageAttachment, userEmail: String) async throws -> MessageAttachment {
        guard attachment.isEncrypted else { return attachment }

        let keys = try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: userEmail)
        let decrypted = try await core.decryptFile(encrypted: attachment.data, keys: keys, msgPwd: nil)

        if let decryptErr = decrypted.decryptErr {
            throw MessageServiceError.attachmentDecryptFailed(decryptErr.error.message)
        }

        guard let decryptSuccess = decrypted.decryptSuccess else {
            throw AppErr.unexpected("decryptFile: expected one of decryptErr, decryptSuccess to be present")
        }

        return MessageAttachment(name: decryptSuccess.name, data: decryptSuccess.data, isEncrypted: false)
    }

    private func processMessage(
        rawMimeData: Data,
        with decrypted: CoreRes.ParseDecryptMsg
    ) async throws -> ProcessedMessage {
        let firstBlockParseErr = decrypted.blocks.first { $0.type == .blockParseErr }
        let firstDecryptErrBlock = decrypted.blocks.first { $0.type == .decryptErr }
        let attachments = try await getAttachments(blocks: decrypted.blocks)
        let messageType: ProcessedMessage.MessageType
        let text: String
        let signature: ProcessedMessage.MessageSignature?

        if let firstBlockParseErr = firstBlockParseErr {
            // Swift failed to parse one of the MsgBlock returned from TypeScript Core
            text = "error_internal_parse_block".localized
            + "\n\n\(firstBlockParseErr.content)"

            messageType = .error(.other)
            signature = nil
        } else if let decryptErrBlock = firstDecryptErrBlock {
            // message failed to decrypt or process
            let err = decryptErrBlock.decryptErr?.error
            let hideContent = err?.type == .badMdc || err?.type == .noMdc
            let rawMsg = hideContent
            ? "content_hidden".localized
            : decryptErrBlock.content

            text = "error_decrypt".localized
            + "\n\(err?.type.rawValue ?? "unknown".localized): \(err?.message ?? "??")\n\n\n\(rawMsg)"
            messageType = .error(err?.type ?? .other)
            signature = nil
        } else {
            // decrypt / process success
            text = decrypted.text
            messageType = decrypted.replyType == ReplyType.encrypted ? .encrypted : .plain
            signature = await evaluateSignatureVerificationResult(
                signature: decrypted.blocks.first?.verifyRes
            )
        }

        return ProcessedMessage(
            rawMimeData: rawMimeData,
            text: text,
            messageType: messageType,
            attachments: attachments,
            signature: signature
        )
    }

    private func getAttachments(
        blocks: [MsgBlock]
    ) async throws -> [MessageAttachment] {
        let attachmentBlocks = blocks.filter(\.isAttachmentBlock)
        let attachments: [MessageAttachment] = attachmentBlocks.compactMap { block in
            guard let meta = block.attMeta else { return nil }

            return MessageAttachment(
                name: meta.name,
                data: meta.data,
                isEncrypted: block.type == .encryptedAtt
            )
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
    private func fetchVerificationPubKeys(for sender: Recipient?, onlyLocal: Bool) async throws -> [String] {
        guard let sender = sender else { return [] }

        let pubKeys = try localContactsProvider.retrievePubKeys(for: sender.email)
        if pubKeys.isNotEmpty || onlyLocal { return pubKeys }

        guard let contact = try? await pubLookup.fetchRemoteUpdateLocal(with: sender)
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
