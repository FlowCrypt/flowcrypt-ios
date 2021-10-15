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

protocol CoreComposeMessageType {
    func composeEmail(msg: SendableMsg, fmt: MsgFmt, pubKeys: [String]?) async throws -> CoreRes.ComposeEmail
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
        email: String
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

        let subject = input.subjectReplyTitle
            ?? contextToSend.subject
            ?? "(no subject)"

        guard let myPubKey = self.dataService.publicKey() else {
            return .failure(.validationError(.missedPublicKey))
        }

        let sendableAttachments: [SendableMsg.Attachment] = contextToSend.attachments
            .map { composeAttachment in
                return SendableMsg.Attachment(
                    name: "\(composeAttachment.name).pgp",
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
                    pubKeys: allRecipientPubs + [myPubKey]
                )
            }
    }

    private func getPubKeys(for recepients: [ComposeMessageRecipient]) -> Result<[String], MessageValidationError> {
        let pubKeys = recepients.map {
            ($0.email, contactsService.retrievePubKey(for: $0.email))
        }

        let emailsWithoutPubKeys = pubKeys.filter { $0.1 == nil }.map(\.0)

        guard emailsWithoutPubKeys.isEmpty else {
            return .failure(.noPubRecipients(emailsWithoutPubKeys))
        }

        return .success(pubKeys.compactMap(\.1))
    }

    // MARK: - Encrypt and Send
    func encryptAndSend(message: SendableMsg, threadId: String?) async throws {
        do {
            let r = try await core.composeEmail(
                msg: message,
                fmt: MsgFmt.encryptInline,
                pubKeys: message.pubKeys
            )

            try await messageGateway.sendMail(input: MessageGatewayInput(mime: r.mimeEncoded, threadId: threadId))
        } catch {
            throw ComposeMessageError.gatewayError(error)
        }
    }
}
