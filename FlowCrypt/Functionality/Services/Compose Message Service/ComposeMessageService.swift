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
    func encryptMsg(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail
    func encryptFile(pubKeys: [String]?, fileData: Data, name: String) async throws -> CoreRes.EncryptFile
}

final class ComposeMessageService {

    private let messageGateway: MessageGateway
    private let storage: EncryptedStorageType
    private let contactsService: ContactsServiceType
    private let core: CoreComposeMessageType & KeyParser
    private let enterpriseServer: EnterpriseServerApiType
    private let draftGateway: DraftGateway?
    private lazy var logger: Logger = Logger.nested(Self.self)

    private struct ReplyInfo: Encodable {
        let sender: String
        let recipient: [String]
        let subject: String
        let token: String
    }

    init(
        clientConfiguration: ClientConfiguration,
        encryptedStorage: EncryptedStorageType,
        messageGateway: MessageGateway,
        draftGateway: DraftGateway? = nil,
        contactsService: ContactsServiceType? = nil,
        core: CoreComposeMessageType & KeyParser = Core.shared,
        enterpriseServer: EnterpriseServerApiType = EnterpriseServerApi()
    ) {
        self.messageGateway = messageGateway
        self.draftGateway = draftGateway
        self.storage = encryptedStorage
        self.contactsService = contactsService ?? ContactsService(
            localContactsProvider: LocalContactsProvider(encryptedStorage: encryptedStorage),
            clientConfiguration: clientConfiguration
        )
        self.core = core
        self.enterpriseServer = enterpriseServer
        self.logger = Logger.nested(in: Self.self, with: "ComposeMessageService")
    }

    private var onStateChanged: ((State) -> Void)?
    func onStateChanged(_ completion: ((State) -> Void)?) {
        self.onStateChanged = completion
    }

    // MARK: - Validation
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
            hasMessagePassword: contextToSend.hasMessagePassword
        )
        let replyToMimeMsg = input.replyToMime
            .flatMap { String(data: $0, encoding: .utf8) }

        return SendableMsg(
            text: text,
            html: nil,
            to: recipients.map(\.email),
            cc: [],
            bcc: [],
            from: email,
            subject: subject,
            replyToMimeMsg: replyToMimeMsg,
            atts: sendableAttachments,
            pubKeys: [myPubKey] + validPubKeys,
            signingPrv: signingPrv,
            password: contextToSend.messagePassword
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

    private func validate(recipients: [RecipientWithSortedPubKeys],
                          hasMessagePassword: Bool) throws -> [String] {
        func contains(keyState: PubKeyState) -> Bool {
            recipients.first(where: { $0.keyState == keyState }) != nil
        }

        logger.logDebug("validate recipients: \(recipients)")
        logger.logDebug("validate recipient keyStates: \(recipients.map(\.keyState))")

        guard hasMessagePassword || !contains(keyState: .empty) else {
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

    // MARK: - Drafts
    private var draft: GTLRGmail_Draft?
    func encryptAndSaveDraft(message: SendableMsg, threadId: String?) async throws {
        do {
            let r = try await core.composeEmail(
                msg: message,
                fmt: .encryptInline
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

            let hasPassword = (message.password ?? "").isNotEmpty
            let composedEmail: CoreRes.ComposeEmail

            if hasPassword {
                composedEmail = try await composePasswordMessage(from: message)
            } else {
                composedEmail = try await core.composeEmail(
                    msg: message,
                    fmt: .encryptInline
                )
            }

            let input = MessageGatewayInput(
                mime: composedEmail.mimeEncoded,
                threadId: threadId
            )

            try await messageGateway.sendMail(
                input: input,
                progressHandler: { [weak self] progress in
                    let progressToShow = hasPassword ? 0.5 + progress / 2 : progress
                    self?.onStateChanged?(.progressChanged(progressToShow))
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

    // MARK: - Message password
    func composePasswordMessage(from message: SendableMsg) async throws -> CoreRes.ComposeEmail {
        let replyToken = try await enterpriseServer.getReplyToken(for: message.from)

        let messageUrl = try await prepareAndUploadPwdEncryptedMsg(
            message: message,
            replyToken: replyToken
        )

        let html = generatePasswordMessageHtml(sender: message.from, url: messageUrl)

        let encryptedTextFile = try await core.encryptMsg(msg: message, fmt: .encryptInline)
        let bodyAttachment = SendableMsg.Attachment(
            name: "encrypted.asc",
            type: "application/pgp-encrypted",
            base64: encryptedTextFile.mimeEncoded.base64EncodedString()
        )

        var encryptedAttachments: [SendableMsg.Attachment] = []

        for attachment in message.atts {
            guard let data = Data(base64Encoded: attachment.base64) else { continue }

            let encryptedFile = try await core.encryptFile(
                pubKeys: message.pubKeys,
                fileData: data,
                name: attachment.name
            )
            let encryptedAttachment = SendableMsg.Attachment(
                name: "\(attachment.name).pgp",
                type: "application/pgp-encrypted",
                base64: encryptedFile.encryptedFile.base64EncodedString()
            )
            encryptedAttachments.append(encryptedAttachment)
        }

        let passwordMessage = SendableMsg(
            text: html,
            html: html,
            to: message.to,
            cc: message.cc,
            bcc: message.bcc,
            from: message.from,
            subject: message.subject,
            replyToMimeMsg: message.replyToMimeMsg,
            atts: [bodyAttachment] + encryptedAttachments,
            pubKeys: nil,
            signingPrv: nil,
            password: nil
        )
        return try await core.composeEmail(msg: passwordMessage, fmt: .plain)
    }

    func prepareAndUploadPwdEncryptedMsg(message: SendableMsg, replyToken: String) async throws -> String {
        let formatted = try await formatPasswordMessage(
            message: message,
            replyToken: replyToken
        )

        let formattedMessage = SendableMsg(
            text: formatted.mimeEncoded.toStr(),
            html: formatted.mimeEncoded.toStr(),
            to: message.to,
            cc: message.cc,
            bcc: message.bcc,
            from: message.from,
            subject: message.subject,
            replyToMimeMsg: message.replyToMimeMsg,
            atts: message.atts,
            pubKeys: [],
            signingPrv: nil,
            password: message.password
        )

        let encoded = try await core.encryptMsg(msg: formattedMessage, fmt: .encryptInline)
        let details = MessageUploadDetails(from: message, replyToken: replyToken)

        return try await enterpriseServer.upload(
            message: encoded.mimeEncoded,
            details: details,
            progressHandler: { [weak self] progress in
                self?.onStateChanged?(.progressChanged(progress / 2))
            }
        )
    }

    func formatPasswordMessage(message: SendableMsg, replyToken: String) async throws -> CoreRes.ComposeEmail {
        let infoDiv = try generateMsgInfoDiv(for: message, replyToken: replyToken)
        let messageText = message.text

        var message = message
        message.text = [messageText, "/n/n", infoDiv].joined()
        message.html = [messageText, "<br><br>", infoDiv].joined()

       return try await core.composeEmail(msg: message, fmt: .plain)
    }

    func generateMsgInfoDiv(for message: SendableMsg, replyToken: String) throws -> String {
        let replyInfo = ReplyInfo(
            sender: message.from,
            recipient: message.to,
            subject: message.subject,
            token: replyToken
        )
        let replyInfoJsonString = try replyInfo.toJsonData().base64EncodedString()
        return "<div style=\"display: none\" class=\"cryptup_reply\" cryptup-data=\"\(replyInfoJsonString)\"></div>"
    }

    func generatePasswordMessageHtml(sender: String, url: String) -> String {
        let aStyle = "padding: 2px 6px; background: #2199e8; color: #fff; display: inline-block; text-decoration: none;"
        return """
        \(sender) has sent you a password-encrypted email <a href="\(url)" style="\(aStyle)">Click here to Open Message</a>
        <br><br>
        Alternatively copy and paste the following link: \(url)
        """
    }
}
