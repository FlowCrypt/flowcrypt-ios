//
//  ComposeMessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI

typealias RecipientState = RecipientEmailsCellNode.Input.State

protocol CoreComposeMessageType {
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail
    func encrypt(data: Data, pubKeys: [String]?, password: String?) async throws -> Data
    func encrypt(file: Data, name: String, pubKeys: [String]?) async throws -> Data
}

enum DraftSaveState {
    case cancelled, saving(ComposedDraft), success(SendableMsg), error(Error)
}

struct ComposedDraft: Equatable {
    let input: ComposeMessageInput
    let contextToSend: ComposeMessageContext
}

final class ComposeMessageService {

    private let appContext: AppContextWithUser
    private let keyMethods: KeyMethodsType
    private let localContactsProvider: LocalContactsProviderType
    private let core: CoreComposeMessageType & KeyParser
    private let draftGateway: DraftGateway?
    private lazy var logger = Logger.nested(Self.self)

    private var saveDraftTask: Task<MessageIdentifier?, Error>?

    private struct ReplyInfo: Encodable {
        let sender: String
        let recipient: [String]
        let subject: String
        let token: String
    }

    private var sender: String { appContext.user.email }

    init(
        appContext: AppContextWithUser,
        keyMethods: KeyMethodsType,
        draftGateway: DraftGateway? = nil,
        core: CoreComposeMessageType & KeyParser = Core.shared,
        localContactsProvider: LocalContactsProviderType? = nil
    ) {
        self.appContext = appContext
        self.keyMethods = keyMethods
        self.draftGateway = draftGateway
        self.core = core
        self.localContactsProvider = localContactsProvider ?? LocalContactsProvider(encryptedStorage: appContext.encryptedStorage)
    }

    private var onStateChanged: ((State) -> Void)?
    func onStateChanged(_ completion: ((State) -> Void)?) {
        self.onStateChanged = completion
    }

    func prepareSigningKey(senderEmail: String) async throws -> Keypair {
        let keys = try await appContext.keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: sender)
        let signingKeys = try await keyMethods.chooseSenderKeys(for: .signing, keys: keys, senderEmail: senderEmail)
        guard let signingKey = signingKeys.first else {
            throw ComposeMessageError.noKeysFoundForSign(keys.count, senderEmail)
        }
        if signingKey.passphrase == nil {
            throw ComposeMessageError.missingPassPhrase(signingKey)
        }
        return signingKey
    }

    func handlePassPhraseEntry(_ passPhrase: String, for signingKey: Keypair) async throws -> Bool {
        // since pass phrase was entered (an inconvenient thing for user to do),
        // let's find all keys that match and save the pass phrase for all
        let allKeys = try await appContext.keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: sender)
        guard allKeys.isNotEmpty else {
            throw KeypairError.noAccountKeysAvailable
        }
        let matchingKeys = try await keyMethods.filterByPassPhraseMatch(keys: allKeys, passPhrase: passPhrase)
        // save passphrase for all matching keys
        try appContext.combinedPassPhraseStorage.savePassPhrasesInMemory(
            for: sender,
            passPhrase,
            privateKeys: matchingKeys
        )
        // now figure out if the pass phrase also matched the signing prv itself
        let matched = matchingKeys.first(where: { $0.allFingerprints.first == signingKey.primaryFingerprint })
        return matched != nil // true if the pass phrase matched signing key
    }

    // MARK: - Validation
    func validateAndProduceSendableMsg(
        input: ComposeMessageInput,
        contextToSend: ComposeMessageContext,
        isDraft: Bool = false,
        withPubKeys: Bool = true
    ) async throws -> SendableMsg {
        let subject = contextToSend.subject ?? ""

        if !isDraft {
            onStateChanged?(.validatingMessage)

            guard contextToSend.recipients.isNotEmpty else {
                throw MessageValidationError.emptyRecipient
            }

            let emails = contextToSend.recipients.map(\.email)
            let emptyEmails = emails.filter { !$0.hasContent }

            guard emails.isNotEmpty, emptyEmails.isEmpty else {
                throw MessageValidationError.emptyRecipient
            }

            guard !emails.contains(where: { !$0.isValidEmail }) else {
                throw MessageValidationError.invalidEmailRecipient
            }

            guard input.isQuote || subject.hasContent else {
                throw MessageValidationError.emptySubject
            }

            guard let text = contextToSend.message, text.hasContent else {
                throw MessageValidationError.emptyMessage
            }

            if let password = contextToSend.messagePassword, password.isNotEmpty {
                if subject.lowercased().contains(password.lowercased()) {
                    throw MessageValidationError.subjectContainsPassword
                }

                let allAvailablePassPhrases = try appContext.combinedPassPhraseStorage.getPassPhrases(for: sender).map(\.value)
                if allAvailablePassPhrases.contains(password) {
                    throw MessageValidationError.notUniquePassword
                }
            }
        }

        let pubKeys = withPubKeys ? try await getPubKeys(
            senderEmail: contextToSend.sender,
            recipients: contextToSend.recipients,
            hasMessagePassword: contextToSend.hasMessagePassword,
            shouldValidate: !isDraft
        ) : []

        let sendableAttachments: [SendableMsg.Attachment] = isDraft
            ? []
            : contextToSend.attachments.map(\.sendableMsgAttachment)
        let signingPrv = isDraft ? nil : try await prepareSigningKey(senderEmail: contextToSend.sender)

        return SendableMsg(
            text: contextToSend.message ?? "",
            html: nil,
            to: contextToSend.recipientEmails(type: .to),
            cc: contextToSend.recipientEmails(type: .cc),
            bcc: contextToSend.recipientEmails(type: .bcc),
            from: contextToSend.sender,
            subject: subject,
            replyToMsgId: input.replyToMsgId,
            inReplyTo: input.inReplyTo,
            atts: sendableAttachments,
            pubKeys: pubKeys,
            signingPrv: signingPrv,
            password: contextToSend.messagePassword
        )
    }

    private func getPubKeys(
        senderEmail: String,
        recipients: [ComposeMessageRecipient],
        hasMessagePassword: Bool,
        shouldValidate: Bool
    ) async throws -> [String] {
        let senderKeys = try await keyMethods.chooseSenderKeys(
            for: .encryption,
            keys: try await appContext.keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: sender),
            senderEmail: senderEmail
        ).map(\.public)

        if shouldValidate, senderKeys.isEmpty {
            throw MessageValidationError.noUsableAccountKeys
        }

        let recipientsWithPubKeys = try await getRecipientKeys(for: recipients)
        if shouldValidate {
            try validate(recipients: recipientsWithPubKeys, hasMessagePassword: hasMessagePassword)
        }
        let validPubKeys = recipientsWithPubKeys.flatMap(\.activePubKeys).map(\.armored)

        return senderKeys + validPubKeys
    }

    private func getRecipientKeys(for composeRecipients: [ComposeMessageRecipient]) async throws -> [RecipientWithSortedPubKeys] {
        let recipients = composeRecipients.map(Recipient.init)
        var recipientsWithKeys: [RecipientWithSortedPubKeys] = []
        for recipient in recipients {
            let armoredPubkeys = try localContactsProvider.retrievePubKeys(
                for: recipient.email,
                shouldUpdateLastUsed: true
            ).joined(separator: "\n")
            let parsed = try await self.core.parseKeys(armoredOrBinary: armoredPubkeys.data())
            recipientsWithKeys.append(
                try RecipientWithSortedPubKeys(recipient, keyDetails: parsed.keyDetails)
            )
        }
        return recipientsWithKeys
    }

    private func validate(
        recipients: [RecipientWithSortedPubKeys],
        hasMessagePassword: Bool
    ) throws {
        func contains(keyState: PubKeyState) -> Bool {
            recipients.contains(where: { $0.keyState == keyState })
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
    }

    // MARK: - Drafts
    var messageIdentifier: MessageIdentifier?

    func fetchMessageIdentifier(info: ComposeMessageInput.MessageQuoteInfo) {
        Task {
            if let draftId = info.draftId {
                messageIdentifier = try await draftGateway?.fetchDraft(id: draftId)
            } else if let messageId = info.rfc822MsgId {
                let identifier = Identifier(stringId: messageId)
                messageIdentifier = try await draftGateway?.fetchDraftIdentifier(for: identifier)
            }
        }
    }

    func saveDraft(message: SendableMsg, threadId: String?, shouldEncrypt: Bool) async throws {
        if let saveDraftTask {
            _ = try await saveDraftTask.value
        }

        saveDraftTask = Task { [weak self] in
            guard let self else { throw AppErr.nilSelf }

            do {
                let mime = try await self.composeEmail(
                    msg: message,
                    fmt: shouldEncrypt ? .encryptInline : .plain
                )

                let threadId = self.messageIdentifier?.threadId?.stringId ?? threadId

                return try await self.draftGateway?.saveDraft(
                    input: MessageGatewayInput(
                        mime: mime,
                        threadId: threadId
                    ),
                    draftId: self.messageIdentifier?.draftId
                )
            } catch {
                throw ComposeMessageError.gatewayError(error)
            }
        }

        messageIdentifier = try await saveDraftTask?.value
        saveDraftTask = nil
    }

    func deleteDraft() async throws {
        guard let draftId = messageIdentifier?.draftId else { return }
        try await draftGateway?.deleteDraft(with: draftId)
    }

    // MARK: - Encrypt and Send
    func composeAndSend(message: SendableMsg, threadId: String?, isPlain: Bool) async throws -> Identifier {
        do {
            onStateChanged?(.startComposing)

            let hasPassword = !message.password.isEmptyOrNil
            let mime: Data

            if hasPassword {
                mime = try await composePasswordMessage(from: message)
            } else {
                mime = try await composeEmail(
                    msg: message,
                    fmt: isPlain ? .plain : .encryptInline
                )
            }

            let input = MessageGatewayInput(
                mime: mime,
                threadId: threadId
            )

            let identifier = try await appContext.getRequiredMailProvider().messageGateway.sendMail(
                input: input,
                progressHandler: { [weak self] progress in
                    let progressToShow = hasPassword ? 0.5 + progress / 2 : progress
                    self?.onStateChanged?(.progressChanged(progressToShow))
                }
            )

            // cleaning any draft saved/created/fetched during editing
            if let draftId = messageIdentifier?.draftId {
                try await draftGateway?.deleteDraft(with: draftId)
            }

            onStateChanged?(.messageSent)

            return identifier
        } catch {
            throw ComposeMessageError.gatewayError(error)
        }
    }

    private func composeEmail(msg: SendableMsg, fmt: MsgFmt = .plain) async throws -> Data {
        try await core.composeEmail(msg: msg, fmt: fmt).mimeEncoded
    }
}

// MARK: - Message password
extension ComposeMessageService {
    private func composePasswordMessage(from message: SendableMsg) async throws -> Data {
        let messageUrl = try await prepareAndUploadPwdEncryptedMsg(message: message)
        let messageBody = createMessageBodyWithPasswordLink(sender: message.from, url: messageUrl)

        let encryptedBodyAttachment = try await encryptBodyWithoutAttachments(message: message)
        let encryptedAttachments = try await encryptAttachments(message: message)

        let sendableMsg = message.copy(
            body: messageBody,
            atts: [encryptedBodyAttachment] + encryptedAttachments,
            pubKeys: nil
        )

        return try await composeEmail(msg: sendableMsg)
    }

    private func encryptBodyWithoutAttachments(message: SendableMsg) async throws -> SendableMsg.Attachment {
        let pubEncryptedNoAttachments = try await core.encrypt(
            data: message.text.data(),
            pubKeys: message.pubKeys,
            password: nil
        )

        return SendableMsg.Attachment(
            name: "encrypted.asc",
            type: "application/pgp-encrypted",
            base64: pubEncryptedNoAttachments.base64EncodedString()
        )
    }

    private func encryptAttachments(message: SendableMsg) async throws -> [SendableMsg.Attachment] {
        var encryptedAttachments: [SendableMsg.Attachment] = []

        for attachment in message.atts {
            guard let data = Data(base64Encoded: attachment.base64) else { continue }

            let encryptedFile = try await core.encrypt(
                file: data,
                name: attachment.name,
                pubKeys: message.pubKeys
            )
            let encryptedAttachment = SendableMsg.Attachment(
                name: "\(attachment.name).pgp",
                type: "application/pgp-encrypted",
                base64: encryptedFile.base64EncodedString()
            )
            encryptedAttachments.append(encryptedAttachment)
        }

        return encryptedAttachments
    }

    private func prepareAndUploadPwdEncryptedMsg(message: SendableMsg) async throws -> String {
        let replyToken = try await appContext.enterpriseServer.getReplyToken()

        let bodyWithReplyToken = try getPwdMsgBodyWithReplyToken(
            message: message,
            replyToken: replyToken
        )
        let msgWithReplyToken = message.copy(
            body: bodyWithReplyToken,
            atts: message.atts,
            pubKeys: nil
        )
        let pgpMimeWithAttachments = try await composeEmail(msg: msgWithReplyToken)

        let pwdEncryptedWithAttachments = try await core.encrypt(
            data: pgpMimeWithAttachments,
            pubKeys: [],
            password: message.password
        )
        let details = MessageUploadDetails(from: msgWithReplyToken, replyToken: replyToken)

        return try await appContext.enterpriseServer.upload(
            message: pwdEncryptedWithAttachments,
            details: details,
            progressHandler: { [weak self] progress in
                self?.onStateChanged?(.progressChanged(progress / 2))
            }
        )
    }

    private func getPwdMsgBodyWithReplyToken(message: SendableMsg, replyToken: String) throws -> SendableMsgBody {
        let replyInfoDiv = try createReplyInfoDiv(for: message, replyToken: replyToken)

        let text = [message.text, "/n/n", replyInfoDiv].joined()
        let html = [message.text, "<br><br>", replyInfoDiv].joined()

        return SendableMsgBody(text: text, html: html)
    }

    private func createReplyInfoDiv(for message: SendableMsg, replyToken: String) throws -> String {
        let replyInfo = ReplyInfo(
            sender: message.from,
            recipient: message.to,
            subject: message.subject,
            token: replyToken
        )
        let replyInfoJsonString = try replyInfo.toJsonData().base64EncodedString()
        return "<div style=\"display: none\" class=\"cryptup_reply\" cryptup-data=\"\(replyInfoJsonString)\"></div>"
    }

    private func createMessageBodyWithPasswordLink(sender: String, url: String) -> SendableMsgBody {
        let text = "compose_password_link".localizeWithArguments(sender, url)
        let aStyle = "padding: 2px 6px; background: #2199e8; color: #fff; display: inline-block; text-decoration: none;"
        let html = """
        \(sender) has sent you a password-encrypted email <a href="\(url)" style="\(aStyle)">Click here to Open Message</a>
        <br><br>
        Alternatively copy and paste the following link: \(url)
        """

        return SendableMsgBody(text: text, html: html)
    }

    func isMessagePasswordStrong(pwd: String) -> Bool {
        let minLength = 8

        // currently password-protected messages are supported only with FES on iOS
        // guard enterpriseServer.isFesUsed else {
        //     // consumers - just 8 chars requirement
        //     return pwd.count >= minLength
        // }

        // enterprise FES - use common corporate password rules
        let predicate = NSPredicate(
            format: "SELF MATCHES %@ ", [
                "(?=.*[a-z])", // 1 lowercase character
                "(?=.*[A-Z])", // 1 uppercase character
                "(?=.*[0-9])", // 1 number
                "(?=.*[\\-@$#!%*?&_,;:'()\"])", // 1 special symbol
                ".{\(minLength),}$" // minimum 8 characters
            ].joined()
        )

        return predicate.evaluate(with: pwd)
    }
}
