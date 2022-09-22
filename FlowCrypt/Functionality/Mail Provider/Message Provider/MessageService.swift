//
//  MessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

// MARK: - MessageFetchState
enum MessageFetchState {
    case fetch, download(Float), decrypt
}

// MARK: - MessageServiceError
enum MessageServiceError: Error, CustomStringConvertible {
    case missingPassPhrase(Keypair?)
    case emptyKeys
    case emptyKeysForEKM
    case attachmentNotFound
    case attachmentDecryptFailed(String)
}

extension MessageServiceError {
    var description: String {
        switch self {
        case .missingPassPhrase:
            return "error_missing_passphrase".localized
        case .emptyKeys:
            return "error_empty_keys".localized
        case .emptyKeysForEKM:
            return "error_empty_keys_for_ekm".localized
        case .attachmentNotFound:
            return "error_attachment_not_found".localized
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
    private let combinedPassPhraseStorage: CombinedPassPhraseStorageType
    private let pubLookup: PubLookupType

    init(
        core: Core = .shared,
        keyMethods: KeyMethodsType = KeyMethods(),
        localContactsProvider: LocalContactsProviderType,
        pubLookup: PubLookupType,
        keyAndPassPhraseStorage: KeyAndPassPhraseStorageType,
        messageProvider: MessageProvider,
        combinedPassPhraseStorage: CombinedPassPhraseStorageType
    ) {
        self.keyAndPassPhraseStorage = keyAndPassPhraseStorage
        self.combinedPassPhraseStorage = combinedPassPhraseStorage
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
        try combinedPassPhraseStorage.savePassPhrasesInMemory(for: userEmail, passPhrase, privateKeys: matchingKeys)
        return matchingKeys.isNotEmpty
    }

    // MARK: - Message processing
    func getAndProcess(
        identifier: Identifier,
        folder: String,
        onlyLocalKeys: Bool,
        userEmail: String,
        isUsingKeyManager: Bool
    ) async throws -> ProcessedMessage {
        let message = try await messageProvider.fetchMessage(
            id: identifier,
            folder: folder
        )
        if message.isPgp {
            return try await decryptAndProcess(
                message: message,
                onlyLocalKeys: onlyLocalKeys,
                userEmail: userEmail,
                isUsingKeyManager: isUsingKeyManager
            )
        } else {
            return ProcessedMessage(message: message)
        }
    }

    func decryptAndProcess(
        message: Message,
        onlyLocalKeys: Bool,
        userEmail: String,
        isUsingKeyManager: Bool
    ) async throws -> ProcessedMessage {
        let keys = try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: userEmail)
        guard keys.isNotEmpty else {
            if isUsingKeyManager {
                throw MessageServiceError.emptyKeysForEKM
            }
            throw MessageServiceError.emptyKeys
        }
        let verificationPubKeys = try await fetchVerificationPubKeys(
            for: message.sender,
            onlyLocal: onlyLocalKeys
        )

        var message = message
        if message.hasSignatureAttachment {
            // raw data is needed for verification of detached signature
            message.raw = try await messageProvider.fetchRawMessage(id: message.identifier)
        }

        let encrypted = message.raw ?? message.body.text
        let decrypted = try await core.parseDecryptMsg(
            encrypted: encrypted.data(),
            keys: keys,
            msgPwd: nil,
            isMime: message.raw != nil,
            verificationPubKeys: verificationPubKeys
        )

        guard !hasMsgBlockThatNeedsPassPhrase(decrypted) else {
            let keyPair = keys.first(where: { $0.passphrase == nil })
            throw MessageServiceError.missingPassPhrase(keyPair)
        }

        return try await process(
            message: message,
            with: decrypted
        )
    }

    private func process(
        message: Message,
        with decrypted: CoreRes.ParseDecryptMsg
    ) async throws -> ProcessedMessage {
        let firstBlockParseErr = decrypted.blocks.first { $0.type == .blockParseErr }
        let firstDecryptErrBlock = decrypted.blocks.first { $0.type == .decryptErr }
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
            message: message,
            text: text,
            type: messageType,
            attachments: message.attachments,
            signature: signature
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

    // MARK: - Attachments processing
    func download(
        attachment: MessageAttachment,
        messageId: Identifier,
        progressHandler: ((Float) -> Void)?
    ) async throws -> Data {
        try await messageProvider.fetchAttachment(
            id: attachment.id,
            messageId: messageId,
            estimatedSize: Float(attachment.size),
            progressHandler: progressHandler
        )
    }

    func decrypt(attachment: MessageAttachment, userEmail: String) async throws -> MessageAttachment {
        guard attachment.isEncrypted, let data = attachment.data else { return attachment }

        let keys = try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: userEmail)
        let decrypted = try await core.decryptFile(encrypted: data, keys: keys, msgPwd: nil)

        if let decryptErr = decrypted.decryptErr {
            throw MessageServiceError.attachmentDecryptFailed(decryptErr.error.message)
        }

        guard let decryptSuccess = decrypted.decryptSuccess else {
            throw AppErr.unexpected("decryptFile: expected one of decryptErr, decryptSuccess to be present")
        }

        return MessageAttachment(
            id: attachment.id,
            name: decryptSuccess.name,
            estimatedSize: attachment.estimatedSize,
            mimeType: attachment.mimeType,
            data: decryptSuccess.data
        )
    }
}

// MARK: - Message verification
extension MessageService {
    private func fetchVerificationPubKeys(for sender: Recipient?, onlyLocal: Bool) async throws -> [String] {
        guard let sender = sender else { return [] }

        let pubKeys = try localContactsProvider.retrievePubKeys(for: sender.email, shouldUpdateLastUsed: false)
        if pubKeys.isNotEmpty || onlyLocal { return pubKeys }

        // try? because we may ignore update remote result
        try? await pubLookup.fetchRemoteUpdateLocal(with: sender)
        guard let contact = try await localContactsProvider.searchRecipient(with: sender.email)
        else { return [] }

        return contact.pubKeys.map(\.armored)
    }

    private func evaluateSignatureVerificationResult(
        signature: MsgBlock.VerifyRes?
    ) async -> ProcessedMessage.MessageSignature {
        guard let signature = signature else { return .unsigned }

        if let error = signature.error {
            if let signer = signature.signer, signature.match == nil {
                if error.starts(with: "Could not find signing key with key ID") {
                    return .missingPubkey(signer)
                }
            }
            return .error(error)
        }

        guard signature.signer != nil else { return .unsigned }

        guard signature.match == true else { return .bad }

        guard signature.partial != true else { return .partial }

        guard signature.mixed != true else { return .goodMixed }

        return .good
    }
}
