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

struct ComposeMessageContext {
    var message: String?
    var recipients: [ComposeMessageRecipient] = []
    var subject: String?
    var attachments: [ComposeMessageAttachment] = []
}

struct ComposeMessageRecipient {
    let email: String
    var state: RecipientState
}

extension ComposeMessageRecipient {
    var isKeyRevoked: Bool {
        if case .keyRevoked = state {
            return true
        } else {
            return false
        }
    }

    var isKeyExpired: Bool {
        if case .keyExpired = state {
            return true
        } else {
            return false
        }
    }
}

protocol CoreComposeMessageType {
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail
}

final class ComposeMessageService {
    private let messageGateway: MessageGateway
    private let dataService: KeyStorageType
    private let contactsService: ContactsServiceType
    private let core: CoreComposeMessageType

    init(
        messageGateway: MessageGateway = MailProvider.shared.messageSender,
        dataService: KeyStorageType = KeyDataStorage(),
        contactsService: ContactsServiceType = ContactsService(),
        core: CoreComposeMessageType = Core.shared
    ) {
        self.messageGateway = messageGateway
        self.dataService = dataService
        self.contactsService = contactsService
        self.core = core
    }

    // MARK: - Validation
    func validateMessage(
        input: ComposeMessageInput,
        contextToSend: ComposeMessageContext,
        email: String,
        signingPrv: PrvKeyInfo?
    ) -> Result<SendableMsg, ComposeMessageError> {
        let recipients = contextToSend.recipients
        guard recipients.isNotEmpty else {
            return .failure(.validationError(.emptyRecipient))
        }

        let emails = recipients.map(\.email)
        let hasContent = emails.filter { $0.hasContent }

        guard emails.isNotEmpty else {
            return .failure(.validationError(.emptyRecipient))
        }

        guard emails.count == hasContent.count else {
            return .failure(.validationError(.emptyRecipient))
        }

        guard input.isReply || contextToSend.subject?.hasContent ?? false else {
            return .failure(.validationError(.emptySubject))
        }

        guard let text = contextToSend.message, text.hasContent else {
            return .failure(.validationError(.emptyMessage))
        }

        guard recipients.filter(\.isKeyRevoked).isEmpty else {
            return .failure(.validationError(.revokedKeyRecipients))
        }

        guard recipients.filter(\.isKeyExpired).isEmpty else {
            return .failure(.validationError(.expiredKeyRecipients))
        }

        let subject = input.subjectReplyTitle
            ?? contextToSend.subject
            ?? "(no subject)"

        guard let myPubKey = self.dataService.publicKey() else {
            return .failure(.validationError(.missedPublicKey))
        }

        let sendableAttachments: [SendableMsg.Attachment] = contextToSend.attachments
            .map { composeAttachment in
                return SendableMsg.Attachment(
                    name: composeAttachment.name,
                    type: composeAttachment.type,
                    base64: composeAttachment.data.base64EncodedString()
                )
            }

        return getPubKeys(for: recipients)
            .mapError { ComposeMessageError.validationError($0) }
            .map { allRecipientPubs in
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
                    pubKeys: allRecipientPubs + [myPubKey],
                    signingPrv: signingPrv
                )
            }
    }

    private func getPubKeys(for recipients: [ComposeMessageRecipient]) -> Result<[String], MessageValidationError> {
        let pubKeys = recipients.map {
            (email: $0.email, keys: contactsService.retrievePubKeys(for: $0.email))
        }

        let emailsWithoutPubKeys = pubKeys.filter { $0.keys.isEmpty }.map(\.email)

        guard emailsWithoutPubKeys.isEmpty else {
            return .failure(.noPubRecipients(emailsWithoutPubKeys))
        }

        return .success(pubKeys.filter({ $0.keys.isNotEmpty }).flatMap(\.keys))
    }

    // MARK: - Encrypt and Send
    func encryptAndSend(message: SendableMsg, threadId: String?, progressHandler: ((Float) -> Void)?) async throws {
        do {
            let r = try await core.composeEmail(
                msg: message,
                fmt: MsgFmt.encryptInline
            )

            try await messageGateway.sendMail(input: MessageGatewayInput(mime: r.mimeEncoded, threadId: threadId),
                                              progressHandler: progressHandler)
        } catch {
            throw ComposeMessageError.gatewayError(error)
        }
    }
}
