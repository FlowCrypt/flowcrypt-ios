//
//  ComposeMessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import FlowCryptUI
import Foundation
import GoogleAPIClientForREST_Gmail
import FlowCryptCommon

struct ComposeMessageContext: Equatable {
    var message: String?
    var recipients: [ComposeMessageRecipient] = []
    var subject: String?
    var attachments: [MessageAttachment] = []
}

struct ComposeMessageRecipient: Equatable {
    let email: String
    var state: RecipientState

    static func == (lhs: ComposeMessageRecipient, rhs: ComposeMessageRecipient) -> Bool {
        return lhs.email == rhs.email
    }
}

protocol CoreComposeMessageType {
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail
}

final class ComposeMessageService {
    private let messageGateway: MessageGateway
    private let dataService: KeyStorageType
    private let contactsService: ContactsServiceType
    private let core: CoreComposeMessageType & KeyParser
    private let draftGateway: DraftGateway?
    private lazy var logger: Logger = Logger.nested(Self.self)

    @Published private(set) var state: State = .idle

    init(
        messageGateway: MessageGateway = MailProvider.shared.messageSender,
        draftGateway: DraftGateway? = MailProvider.shared.draftGateway,
        dataService: KeyStorageType = KeyDataStorage(),
        contactsService: ContactsServiceType = ContactsService(),
        core: CoreComposeMessageType & KeyParser = Core.shared
    ) {
        self.messageGateway = messageGateway
        self.draftGateway = draftGateway
        self.dataService = dataService
        self.contactsService = contactsService
        self.core = core
        self.logger = Logger.nested(in: Self.self, with: "ComposeMessageService")
    }

    func validateAndProduceSendableMsg(
        input: ComposeMessageInput,
        contextToSend: ComposeMessageContext,
        email: String,
        includeAttachments: Bool = true,
        signingPrv: PrvKeyInfo?
    ) async throws -> SendableMsg {
        state = .validatingMessage

        let recipients = contextToSend.recipients
        guard recipients.isNotEmpty else {
            state = .error
            throw MessageValidationError.emptyRecipient
        }

        let emails = recipients.map(\.email)
        let emptyEmails = emails.filter { !$0.hasContent }

        guard emails.isNotEmpty, emptyEmails.isEmpty else {
            state = .error
            throw MessageValidationError.emptyRecipient
        }

        guard emails.filter({ !$0.isValidEmail }).isEmpty else {
            state = .error
            throw MessageValidationError.invalidEmailRecipient
        }

        guard input.isQuote || contextToSend.subject?.hasContent ?? false else {
            state = .error
            throw MessageValidationError.emptySubject
        }

        guard let text = contextToSend.message, text.hasContent else {
            state = .error
            throw MessageValidationError.emptyMessage
        }

        let subject = contextToSend.subject ?? "(no subject)"

        guard let myPubKey = self.dataService.publicKey() else {
            state = .error
            throw MessageValidationError.missedPublicKey
        }

        let sendableAttachments: [SendableMsg.Attachment] = includeAttachments
                ? contextToSend.attachments.map { $0.toSendableMsgAttachment() }
                : []

        let allRecipientPubs = try await getPubKeys(for: recipients)
        let replyToMimeMsg = input.replyToMime
            .flatMap { String(data: $0, encoding: .utf8) }

        return SendableMsg(
            text: text,
            to: recipients.map(\.email),
            cc: [],
            bcc: [],
            from: email,
            subject: subject,
            replyToMimeMsg: replyToMimeMsg,
            atts: sendableAttachments,
            pubKeys: [myPubKey] + allRecipientPubs,
            signingPrv: signingPrv
        )
    }

    private func getPubKeys(for recipients: [ComposeMessageRecipient]) async throws -> [String] {
        var recipientsWithKeys: [RecipientWithSortedPubKeys] = []
        for recipient in recipients {
            let armoredPubkeys = contactsService.retrievePubKeys(for: recipient.email).joined(separator: "\n")
            let parsed = try await self.core.parseKeys(armoredOrBinary: armoredPubkeys.data())
            recipientsWithKeys.append(RecipientWithSortedPubKeys(email: recipient.email, keyDetails: parsed.keyDetails))
        }
        return try validate(recipients: recipientsWithKeys)
    }

    private func validate(recipients: [RecipientWithSortedPubKeys]) throws -> [String] {
        func contains(keyState: PubKeyState) -> Bool {
            recipients.first(where: { $0.keyState == keyState }) != nil
        }
        logger.logDebug("validate recipients: \(recipients)")
        logger.logDebug("validate recipient keyStates: \(recipients.map { $0.keyState })")
        guard !contains(keyState: .empty) else {
            state = .error
            throw MessageValidationError.noPubRecipients
        }
        guard !contains(keyState: .expired) else {
            state = .error
            throw MessageValidationError.expiredKeyRecipients
        }
        guard !contains(keyState: .revoked) else {
            state = .error
            throw MessageValidationError.revokedKeyRecipients
        }
        return recipients.flatMap(\.activePubKeys).map(\.armored)
    }

    private var draft: GTLRGmail_Draft?
    func encryptAndSaveDraft(message: SendableMsg, threadId: String?) async throws {
        do {
            let r = try await core.composeEmail(
                msg: message,
                fmt: MsgFmt.encryptInline
            )
            draft = try await draftGateway?.saveDraft(input: MessageGatewayInput(mime: r.mimeEncoded, threadId: threadId), draft: draft)
        } catch {
            state = .error
            throw ComposeMessageError.gatewayError(error)
        }
    }

    // MARK: - Encrypt and Send
    func encryptAndSend(message: SendableMsg, threadId: String?) async throws {
        do {
            state = .startComposing
            let r = try await core.composeEmail(
                msg: message,
                fmt: MsgFmt.encryptInline
            )

            try await messageGateway.sendMail(
                input: MessageGatewayInput(mime: r.mimeEncoded, threadId: threadId),
                progressHandler: { [weak self] progress in
                    self?.state = .progressChanged(progress)
                }
            )

            // cleaning any draft saved/created/fetched during editing
            if let draftId = draft?.identifier {
                await draftGateway?.deleteDraft(with: draftId)
            }
            state = .messageSent
        } catch {
            state = .error
            throw ComposeMessageError.gatewayError(error)
        }
    }
}

extension ComposeMessageService {
    enum State {
        case idle
        case validatingMessage
        case startComposing
        case progressChanged(Float)
        case messageSent
        case error

        var message: String? {
            switch self {
            case .idle, .error:
                return nil
            case .validatingMessage:
                return "Validating"
            case .startComposing, .progressChanged:
                return "Composing"
            case .messageSent:
                return "Message sent"
            }
        }

        var progress: Float? {
            guard case .progressChanged(let progress) = self else {
                return nil
            }
            return progress
        }
    }
}
