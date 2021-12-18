//
//  ComposeMessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import Foundation
import GoogleAPIClientForREST_Gmail
import FlowCryptCommon

typealias RecipientState = RecipientEmailsCellNode.Input.State

protocol CoreComposeMessageType {
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail
}

final class ComposeMessageService {

    private let messageGateway: MessageGateway
    private let storage: EncryptedStorageType
    private let contactsService: ContactsServiceType
    private let core: CoreComposeMessageType & KeyParser
    private let draftGateway: DraftGateway?
    private lazy var logger: Logger = Logger.nested(Self.self)

    init(
        clientConfiguration: ClientConfiguration,
        encryptedStorage: EncryptedStorageType,
        messageGateway: MessageGateway,
        draftGateway: DraftGateway? = nil,
        contactsService: ContactsServiceType? = nil,
        core: CoreComposeMessageType & KeyParser = Core.shared
    ) {
        self.messageGateway = messageGateway
        self.draftGateway = draftGateway
        self.storage = encryptedStorage
        self.contactsService = contactsService ?? ContactsService(
            localContactsProvider: LocalContactsProvider(encryptedStorage: encryptedStorage),
            clientConfiguration: clientConfiguration
        )
        self.core = core
        self.logger = Logger.nested(in: Self.self, with: "ComposeMessageService")
    }

    private var onStateChanged: ((State) -> Void)?
    func onStateChanged(_ completion: ((State) -> Void)?) {
        self.onStateChanged = completion
    }

    func validateAndProduceSendableMsg(
        input: ComposeMessageInput,
        contextToSend: ComposeMessageContext,
        email: String,
        includeAttachments: Bool = true,
        signingPrv: PrvKeyInfo?
    ) async throws -> SendableMsg {
        onStateChanged?(.validatingMessage)

        let recipients = contextToSend.recipients
        guard recipients.isNotEmpty else {
            throw MessageValidationError.emptyRecipient
        }

        let emails = recipients.map(\.email)
        let emptyEmails = emails.filter { !$0.hasContent }

        guard emails.isNotEmpty, emptyEmails.isEmpty else {
            throw MessageValidationError.emptyRecipient
        }

        guard emails.filter({ !$0.isValidEmail }).isEmpty else {
            throw MessageValidationError.invalidEmailRecipient
        }

        guard input.isQuote || contextToSend.subject?.hasContent ?? false else {
            throw MessageValidationError.emptySubject
        }

        guard let text = contextToSend.message, text.hasContent else {
            throw MessageValidationError.emptyMessage
        }

        let subject = contextToSend.subject ?? "(no subject)"

        guard let myPubKey = storage.getKeypairs(by: email).map(\.public).first else {
            throw MessageValidationError.missedPublicKey
        }

        let sendableAttachments: [SendableMsg.Attachment] = includeAttachments
                ? contextToSend.attachments.map { $0.toSendableMsgAttachment() }
                : []

        let recipientsWithPubKeys = try await getRecipientKeys(for: recipients)
        let validPubKeys = try validate(
            recipients: recipientsWithPubKeys,
            withMessagePassword: contextToSend.hasPassword
        )
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
            pubKeys: [myPubKey] + validPubKeys,
            signingPrv: signingPrv,
            password: contextToSend.password
        )
    }

    private func getRecipientKeys(for recipients: [ComposeMessageRecipient]) async throws -> [RecipientWithSortedPubKeys] {
        var recipientsWithKeys: [RecipientWithSortedPubKeys] = []
        for recipient in recipients {
            let armoredPubkeys = contactsService.retrievePubKeys(for: recipient.email).joined(separator: "\n")
            let parsed = try await self.core.parseKeys(armoredOrBinary: armoredPubkeys.data())
            recipientsWithKeys.append(RecipientWithSortedPubKeys(email: recipient.email, keyDetails: parsed.keyDetails))
        }
        return recipientsWithKeys
    }

    private func validate(recipients: [RecipientWithSortedPubKeys], withMessagePassword: Bool) throws -> [String] {
        func contains(keyState: PubKeyState) -> Bool {
            recipients.first(where: { $0.keyState == keyState }) != nil
        }

        func hasRecipientsWithoutPubKey(withPasswordSupport: Bool) -> Bool {
            recipients
                .filter { $0.keyState == .empty }
                .first(where: {
                    guard let domain = $0.email.recipientDomain else { return !withPasswordSupport }
                    let supportsPassword = domainsWithPasswordSupport.contains(domain)
                    return withPasswordSupport == supportsPassword
                }) != nil
        }

        logger.logDebug("validate recipients: \(recipients)")
        logger.logDebug("validate recipient keyStates: \(recipients.map(\.keyState))")

        let domainsWithPasswordSupport = ["flowcrypt.com"]

        guard withMessagePassword || !hasRecipientsWithoutPubKey(withPasswordSupport: true) else {
            throw MessageValidationError.needsMessagePassword
        }

        guard !hasRecipientsWithoutPubKey(withPasswordSupport: false) else {
            throw MessageValidationError.noPubRecipients
        }

        guard !contains(keyState: .expired) else {
            throw MessageValidationError.expiredKeyRecipients
        }
        guard !contains(keyState: .revoked) else {
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
            throw ComposeMessageError.gatewayError(error)
        }
    }

    // MARK: - Encrypt and Send
    func encryptAndSend(message: SendableMsg, threadId: String?) async throws {
        do {
            onStateChanged?(.startComposing)
            let r = try await core.composeEmail(
                msg: message,
                fmt: MsgFmt.encryptInline
            )

            try await messageGateway.sendMail(
                input: MessageGatewayInput(mime: r.mimeEncoded, threadId: threadId),
                progressHandler: { [weak self] progress in
                    self?.onStateChanged?(.progressChanged(progress))
                }
            )

            // cleaning any draft saved/created/fetched during editing
            if let draftId = draft?.identifier {
                await draftGateway?.deleteDraft(with: draftId)
            }
            onStateChanged?(.messageSent)
        } catch {
            throw ComposeMessageError.gatewayError(error)
        }
    }
}
